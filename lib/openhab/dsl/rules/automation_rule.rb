# frozen_string_literal: true

module OpenHAB
  module DSL
    module Rules
      #
      # OpenHAB rules engine object
      #
      # @!visibility private
      class AutomationRule < org.openhab.core.automation.module.script.rulesupport.shared.simple.SimpleRule
        # @!visibility private
        INPUT_KEY_PATTERN = /^[a-z_]+[a-zA-Z0-9_]*$/.freeze

        class << self
          #
          # Caches dynamically generated Struct classes so that they don't have
          # to be re-generated for every event, blowing the method cache.
          #
          # @!visibility private
          # @return [java.util.Map<Array<Symbol>, Class>]
          attr_reader :event_structs
        end
        @event_structs = java.util.concurrent.ConcurrentHashMap.new

        field_writer :uid

        #
        # Create a new Rule
        #
        # @param [Config] config Rule configuration
        #
        # Constructor sets a number of variables, no further decomposition necessary
        #
        def initialize(config)
          super()
          set_name(config.name)
          set_description(config.description)
          tags = DSL::Items::ItemBuilder.normalize_tags(*config.tags)
          set_tags(tags.to_set)
          set_triggers(config.triggers)
          self.uid = config.uid
          @run_context = config.caller
          @run_queue = config.run
          @guard = config.guard
          @between = config.between && DSL.between(config.between)
          @trigger_conditions = config.trigger_conditions
          @trigger_conditions.each_value do |condition|
            condition.rule = self if condition.respond_to?(:rule=)
          end
          @attachments = config.attachments
          @thread_locals = ThreadLocal.persist
          @cleanup_hooks = Set.new
          @listener = nil
          debounce_settings = config.debounce_settings || { for: nil }
          @debouncer = Debouncer.new(**debounce_settings)
        end

        #
        # Execute the rule
        #
        # @param [java.util.Map] mod map provided by openHAB rules engine
        # @param [java.util.Map] inputs map provided by openHAB rules engine containing event and other information
        #
        def execute(mod = nil, inputs = nil)
          execute!(mod, inputs)
        end

        # @!visibility private
        def on_removal(listener)
          @cleanup_hooks << listener
          listen_for_removal unless @listener
        end

        private

        # This method gets called in rspec's SuspendRules as well
        def execute!(mod, inputs)
          ThreadLocal.thread_local(**@thread_locals) do
            logger.trace { "Execute called with mod (#{mod&.to_string}) and inputs (#{inputs.inspect})" }
            logger.trace { "Event details #{inputs["event"].inspect}" } if inputs&.key?("event")
            trigger_conditions(inputs).process(mod: mod, inputs: inputs) do
              event = extract_event(inputs)
              @debouncer.call { process_queue(create_queue(event), mod, event) }
            end
          rescue Exception => e
            raise if defined?(::RSpec) && ::RSpec.current_example.example_group.propagate_exceptions?

            @run_context.send(:logger).log_exception(e)
          end
        end

        def cleanup
          @cleanup_hooks.each(&:cleanup)
        end

        def listen_for_removal
          @listener ||= org.openhab.core.common.registry.RegistryChangeListener.impl do |method, element|
            next unless method == :removed

            logger.trace("Rule #{element.inspect} removed from registry")
            next unless element.uid == uid

            cleanup
            $rules.remove_registry_change_listener(@listener)
          end
          $rules.add_registry_change_listener(@listener)
        end

        #
        # Create the run queue based on guards
        #
        # @param [Map] event Event object
        # @return [Queue] <description>
        #
        def create_queue(event)
          case check_guards(event: event)
          when true
            @run_queue.dup.grep_v(BuilderDSL::Otherwise)
          when false
            @run_queue.dup.grep(BuilderDSL::Otherwise)
          end
        end

        #
        # Extract the event object from inputs
        # and merge other inputs keys/values into the event
        #
        # @param [Map] inputs rule inputs
        #
        # @return [Object] event object
        #
        def extract_event(inputs)
          attachment = @attachments[trigger_id(inputs)]
          if inputs&.key?("event")
            event = inputs["event"]
            unless event
              if attachment
                logger.warn("Unable to attach #{attachment.inspect} to event " \
                            "object for rule #{uid} since the event is nil.")
              end
              return nil
            end

            event.attachment = attachment
            return event
          end

          inputs = inputs.to_h
                         .select { |key, _value| key != "module" && INPUT_KEY_PATTERN.match?(key) }
                         .transform_keys(&:to_sym)
          inputs[:attachment] = attachment
          keys = inputs.keys.sort
          struct_class = self.class.event_structs.compute_if_absent(keys) do
            Struct.new(*keys, keyword_init: true)
          end
          struct_class.new(**inputs)
        end

        #
        # Get the trigger_id for the trigger that caused the rule creation
        #
        # @return [Hash] Input hash potentially containing trigger id
        #
        def trigger_id(inputs)
          inputs&.dig("module")
        end

        #
        # Returns trigger conditions from inputs if it exists
        #
        # @param [java.util.Map] inputs map from openHAB containing UID
        #
        # @return [Array] Array of trigger conditions that match rule UID
        #
        def trigger_conditions(inputs)
          @trigger_conditions[trigger_id(inputs)]
        end

        #
        # Check if any guards prevent execution
        #
        # @param [Object] event openHAB rule trigger event
        #
        # @return [true,false] True if guards says rule should execute, false otherwise
        #
        # Loggging inflates method length
        def check_guards(event:)
          return true if @guard.nil?

          unless @between.nil?
            now = Time.now
            unless @between.cover?(now)
              logger.trace("Skipped execution of rule '#{name}' because the current time #{now} " \
                           "is not between #{@between.begin} and #{@between.end}")
              return false
            end
          end

          return true if @guard.should_run?(event)

          logger.trace("Skipped execution of rule '#{name}' because of guard #{@guard}")
          false
        end

        #
        # Process the run queue
        #
        # @param [Array] run_queue array of procs of various types to execute
        # @param [java.util/Map] mod openHAB map object describing rule trigger
        # @param [Object] event openHAB map object describing rule trigger
        #
        def process_queue(run_queue, mod, event)
          while (task = run_queue.shift)
            if task.is_a?(BuilderDSL::Delay)
              process_delay_task(event, mod, run_queue, task)
            else
              process_task(event, task)
            end
          end
        end

        #
        # Dispatch execution block tasks to different methods
        #
        # @param [OpenHab Event] event that triggered the rule
        # @param [Task] task task containing otherwise block to execute
        #
        def process_task(event, task)
          ThreadLocal.thread_local(**@thread_locals) do
            case task
            when BuilderDSL::Run then process_run_task(event, task)
            when BuilderDSL::Script then process_script_task(task)
            when BuilderDSL::Trigger then process_trigger_task(event, task)
            when BuilderDSL::Otherwise then process_otherwise_task(event, task)
            end
          end
        end

        #
        # Process an otherwise block
        #
        # @param [OpenHab Event] event that triggered the rule
        # @param [Task] task task containing otherwise block to execute
        #
        #
        def process_otherwise_task(event, task)
          logger.trace { "Executing rule '#{name}' otherwise block with event(#{event})" }
          @run_context.instance_exec(event, &task.block)
        end

        #
        # Process delay task
        #
        # @param [Map] event Rule trigger event
        # @param [Map] mod Rule modes
        # @param [Queue] run_queue Queue of tasks for this rule
        # @param [Delay] task to process
        #
        #
        def process_delay_task(event, mod, run_queue, task)
          remaining_queue = run_queue.slice!(0, run_queue.length)
          DSL.after(task.duration) { process_queue(remaining_queue, mod, event) }
        end

        #
        # Process a task that is caused by a group item
        #
        # @param [Map] event Rule event map
        # @param [Trigger] task to execute
        #
        #
        def process_trigger_task(event, task)
          return unless event&.item

          logger.trace { "Executing rule '#{name}' trigger block with item (#{event.item})" }
          @run_context.instance_exec(event.item, &task.block)
        end

        #
        # Process a run task
        #
        # @param [OpenHab Event] event information
        # @param [Run] task to execute
        #
        #
        def process_run_task(event, task)
          logger.trace { "Executing rule '#{name}' run block with event(#{event})" }
          @run_context.instance_exec(event, &task.block)
        end

        #
        # Process a script task
        #
        # @param [Script] task to execute
        #
        def process_script_task(task)
          logger.trace { "Executing script '#{name}' run block" }
          @run_context.instance_exec(&task.block)
        end

        #
        # Create a new hash in which all elements are converted to strings
        #
        # @param [Map] hash in which all elements should be converted to strings
        #
        # @return [Map] new map with values converted to strings
        #
        def inspect_hash(hash)
          hash.each_with_object({}) do |(key, value), new_hash|
            new_hash[inspect_item(key)] = inspect_item(value)
          end
        end

        #
        # Convert an individual element into a string based on if it a Ruby or Java object
        #
        # @param [Object] item to convert to a string
        #
        # @return [String] representation of item
        #
        def inspect_item(item)
          if item.respond_to? :to_string
            item.to_string
          elsif item.respond_to? :to_str
            item.to_str
          end
        end
      end
    end
  end
end

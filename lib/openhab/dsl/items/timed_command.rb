# frozen_string_literal: true

module OpenHAB
  module DSL
    module Items
      # Extensions for {Item} to implement timed commands
      #
      # All items have an implicit timer associated with them, enabling to
      # easily set an item into a specific state for a specified duration and
      # then at the expiration of that duration have the item automatically
      # change to another state. These timed commands are reentrant, meaning
      # if the same timed command is triggered while an outstanding timed
      # command exist, that timed command will be rescheduled rather than
      # creating a distinct timed command.
      #
      # Timed commands are initiated by using the 'for:' argument with the
      # command. This is available on both the 'command' method and any
      # command-specific methods, e.g. {SwitchItem#on}.
      #
      # The timer will be cancelled, and the item's state will not be changed
      # to the on_expire state if:
      # - The item receives any command within the timed command duration.
      # - The item is updated to a different state, even if it is then updated
      #   back to the same state.
      #
      # For example, if you have a Switch on a timer and another rule sends
      # a command to that item, even when it's commanded to the same state,
      # the timer will be automatically canceled.
      #
      # Sending a different duration (for:) value for the timed
      # command will reschedule the timed command for that new duration.
      #
      module TimedCommand
        #
        # Provides information about why the expiration block of a
        # {TimedCommand#command timed command} is being called.
        #
        # @attr [Item] item
        #   The item that the timed command was sent to.
        # @attr [Types::Type, Proc] on_expire
        #   @!visibility private
        # @attr [Core::Timer] timer
        #   @!visibility private
        # @attr [Symbol] resolution
        #   @!visibility private
        # @attr [String] rule_uid
        #   @!visibility private
        # @attr [Mutex] mutex
        #   @!visibility private
        #
        TimedCommandDetails = Struct.new(:item,
                                         :on_expire,
                                         :timer,
                                         :resolution,
                                         :rule_uid,
                                         :mutex,
                                         keyword_init: true) do
          # @return [true, false]
          def expired?
            resolution == :expired
          end

          # @return [true, false]
          def cancelled?
            resolution == :cancelled
          end

          #
          # Reschedule the timed command.
          #
          # If the timed command was cancelled, this will also resume it.
          #
          # @param [java.time.temporal.TemporalAmount, #to_zoned_date_time, Proc, nil] time
          #   When to reschedule the timer for. If unspecified, the original time is used.
          # @return [void]
          #
          def reschedule(time = nil)
            self.resolution = nil
            timer.reschedule(time)
          end

          #
          # Resume a cancelled timed command to its original expiration time.
          #
          # @return [void]
          #
          def resume
            if expired?
              logger.warn "Cannot resume a timed command that has expired. Use reschedule instead."
            else
              self.resolution = nil
            end
          end
        end

        @timed_commands = java.util.concurrent.ConcurrentHashMap.new

        class << self
          # @!visibility private
          attr_reader :timed_commands
        end

        Core::Items::Item.prepend(self)
        Core::Items::GroupItem.prepend(self)

        #
        # Sends command to an item for specified duration, then on timer expiration sends
        # the expiration command to the item
        #
        # @note If a block is provided, and the timer is canceled because the
        #   item changed state while it was waiting, the block will still be
        #   executed. The timed command can be reinstated by calling {TimedCommandDetails#resume #resume} or
        #   {TimedCommandDetails#reschedule #reschedule}.
        #
        #   If the timer expired, the timed command can be rescheduled from inside the block by calling
        #   {TimedCommandDetails#reschedule #reschedule}.
        #
        #   Be sure to check {TimedCommandDetails#expired? #expired?}
        #   and/or {TimedCommandDetails#cancelled? #cancelled?} to determine why
        #   the block was called.
        #
        # @param [Command] command to send to object
        # @param [Duration] for duration for item to be in command state
        # @param [Command] on_expire Command to send when duration expires
        # @param [true, false] only_when_ensured if true, only start the timed command if the command was ensured
        # @yield If a block is provided, `on_expire` is ignored and the block
        #   is expected to set the item to the desired state or carry out some
        #   other action.
        # @yieldparam [TimedCommandDetails] timed_command
        # @return [self]
        #
        # @example
        #   Switch.command(ON, for: 5.minutes)
        # @example
        #   Switch.on for: 5.minutes
        # @example
        #   Dimmer.on for: 5.minutes, on_expire: 50
        # @example
        #   Dimmer.on(for: 5.minutes) { |event| Dimmer.off if Light.on? }
        #
        # @example Only start a timed command if the command was ensured
        #   rule "Motion Detected" do
        #     received_command Motion_Sensor, command: ON
        #     run do
        #       # Start the timer only if the command was ensured
        #       # i.e. the light was off before the command was sent
        #       # but if the timer was already started, extend it
        #       FrontPorchLight.ensure.on for: 30.minutes, only_when_ensured: true
        #     end
        #   end
        #
        def command(command, for: nil, on_expire: nil, only_when_ensured: false, **kwargs, &block)
          duration = binding.local_variable_get(:for)
          return super(command, **kwargs) unless duration

          on_expire = block if block

          create_ensured_timed_command = proc do
            on_expire ||= default_on_expire(command)
            if only_when_ensured
              DSL.ensure_states do
                create_timed_command(command, duration:, on_expire:) if super(command, **kwargs)
              end
            else
              super(command, **kwargs)
              create_timed_command(command, duration:, on_expire:)
            end
          end

          TimedCommand.timed_commands.compute(self) do |_key, timed_command_details|
            if timed_command_details.nil?
              # no prior timed command
              create_ensured_timed_command.call
            else
              timed_command_details.mutex.synchronize do
                if timed_command_details.resolution
                  # timed command that finished, but hadn't removed itself from the map yet
                  # (it doesn't do so under the mutex to prevent a deadlock).
                  # just create a new one
                  create_ensured_timed_command.call
                else
                  # timed command still pending; reset it
                  logger.trace { "Outstanding Timed Command #{timed_command_details} encountered - rescheduling" }
                  timed_command_details.on_expire = on_expire unless on_expire.nil?
                  timed_command_details.timer.reschedule(duration)
                  # disable the cancel rule while we send the new command
                  DSL.rules[timed_command_details.rule_uid].disable
                  super(command, **kwargs) # This returns nil when "ensured"
                  DSL.rules[timed_command_details.rule_uid].enable
                  timed_command_details
                end
              end
            end
          end

          self
        end

        private

        # Creates a new timed command and places it in the TimedCommand hash
        def create_timed_command(command, duration:, on_expire:)
          timed_command_details = TimedCommandDetails.new(item: self,
                                                          on_expire:,
                                                          mutex: Mutex.new)

          timed_command_details.timer = timed_command_timer(timed_command_details, duration)
          cancel_rule = TimedCommandCancelRule.new(command, timed_command_details)
          unmanaged_rule = Core.automation_manager.add_unmanaged_rule(cancel_rule)
          timed_command_details.rule_uid = unmanaged_rule.uid
          Core::Rules::Provider.current.add(unmanaged_rule)
          logger.trace { "Created Timed Command #{timed_command_details}" }
          timed_command_details
        end

        # Creates the timer to handle changing the item state when timer expires or invoking user supplied block
        # @param [TimedCommandDetails] timed_command_details details about the timed command
        # @return [Timer] Timer
        def timed_command_timer(timed_command_details, duration)
          DSL.after(duration) do
            timed_command_details.mutex.synchronize do
              logger.trace { "Timed command expired - #{timed_command_details}" }
              DSL.rules[timed_command_details.rule_uid].disable
              timed_command_details.resolution = :expired
              case timed_command_details.on_expire
              when Proc
                logger.trace do
                  "Invoking block #{timed_command_details.on_expire} after timed command for #{name} expired"
                end
                timed_command_details.on_expire.call(timed_command_details)
              when Core::Types::UnDefType
                update(timed_command_details.on_expire)
              else
                command(timed_command_details.on_expire)
              end
              # The on_expire block can call timed_command_details.reschedule, which sets resolution to nil
              # to prevent removal of the timed command
              if timed_command_details.resolution
                DSL.rules.remove(timed_command_details.rule_uid)
                TimedCommand.timed_commands.delete(timed_command_details.item)
              else
                DSL.rules[timed_command_details.rule_uid].enable
                logger.trace { "Block rescheduled the timer to #{timed_command_details.timer.execution_time}" }
              end
            end
          end
        end

        #
        # The default expire for ON/OFF is their inverse
        #
        def default_on_expire(command)
          return !command if command.is_a?(Core::Types::OnOffType)

          raw_state
        end

        #
        # Rule to cancel timed commands
        #
        # @!visibility private
        class TimedCommandCancelRule < org.openhab.core.automation.module.script.rulesupport.shared.simple.SimpleRule
          def initialize(command, timed_command_details)
            super()
            @timed_command_details = timed_command_details
            # Capture rule name if known
            @thread_locals = ThreadLocal.persist
            self.name = "Cancel implicit timer for #{timed_command_details.item.name}"
            self.triggers = [
              Rules::RuleTriggers.trigger(
                type: Rules::Triggers::Changed::ITEM_STATE_CHANGE,
                config: {
                  "itemName" => timed_command_details.item.name,
                  "previousState" => timed_command_details.item.format_command(command).to_s
                }
              ),
              Rules::RuleTriggers.trigger(
                type: Rules::Triggers::Command::ITEM_COMMAND,
                config: {
                  "itemName" => timed_command_details.item.name
                }
              )
            ]
            self.visibility = Core::Rules::Visibility::HIDDEN
          end

          #
          # Execute the rule
          #
          # @param [java.util.Map] _mod map provided by openHAB rules engine
          # @param [java.util.Map] inputs map provided by openHAB rules engine containing event and other information
          #
          def execute(_mod = nil, inputs = nil)
            ThreadLocal.thread_local(**@thread_locals) do
              @timed_command_details.mutex.synchronize do
                logger.trace do
                  "Canceling implicit timer #{@timed_command_details.timer} for " \
                    "#{@timed_command_details.item.name} because of received event #{inputs}"
                end
                original_execution_time = @timed_command_details.timer.execution_time
                @timed_command_details.timer.cancel
                DSL.rules[@timed_command_details.rule_uid].disable
                @timed_command_details.resolution = :cancelled
                if @timed_command_details.on_expire.is_a?(Proc)
                  logger.trace "Executing user supplied block on timed command cancelation"
                  @timed_command_details.on_expire.call(@timed_command_details)
                end
                if @timed_command_details.resolution
                  DSL.rules.remove(@timed_command_details.rule_uid)
                  TimedCommand.timed_commands.delete(@timed_command_details.item)
                else
                  DSL.rules[@timed_command_details.rule_uid].enable
                  @timed_command_details.timer.reschedule(original_execution_time)
                end
              end
            rescue Exception => e
              raise if defined?(::RSpec)

              logger.log_exception(e)
            end
          end
        end
      end
    end
  end
end

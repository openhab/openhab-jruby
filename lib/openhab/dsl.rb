# frozen_string_literal: true

require "java"
require "method_source"

require "bundler/inline"

require_relative "log"
require_relative "osgi"
require_relative "core"

Dir[File.expand_path("dsl/**/*.rb", __dir__)].each do |f|
  # some files are excluded because they're autoloaded
  require f unless f.include?("/rules/") || f =~ %r{dsl/(items|sitemaps|things)/builder.rb$}
end

require_relative "core_ext"

#
# Main openHAB Module
#
module OpenHAB
  #
  # The main DSL available to rules.
  #
  # Methods on this module are extended onto `main`, the top level `self` in
  # any file. You can also access them as class methods on the module for use
  # inside of other classes, or include the module.
  #
  module DSL
    module Items
      autoload :Builder, "openhab/dsl/items/builder"
      autoload :BaseBuilderDSL, "openhab/dsl/items/builder"
      autoload :ItemBuilder, "openhab/dsl/items/builder"
    end

    module Things
      autoload :Builder, "openhab/dsl/things/builder"
    end

    module Sitemaps
      autoload :Builder, "openhab/dsl/sitemaps/builder"
      autoload :LinkableWidgetBuilder, "openhab/dsl/sitemaps/builder"
    end

    module Rules
      # sorted alphabetically
      autoload :AutomationRule, "openhab/dsl/rules/builder"
      autoload :Builder, "openhab/dsl/rules/builder"
      autoload :Guard, "openhab/dsl/rules/builder"
      autoload :NameInference, "openhab/dsl/rules/builder"
      autoload :Property, "openhab/dsl/rules/builder"
      autoload :RuleTriggers, "openhab/dsl/rules/builder"
      autoload :Terse, "openhab/dsl/rules/builder"
      autoload :Triggers, "openhab/dsl/rules/builder"
    end

    # include this before Core::Actions so that Core::Action's method_missing
    # takes priority
    include Core::EntityLookup

    #
    # @!parse
    #   include Core::Actions
    #   include Core::ScriptHandling
    #   include Rules::Terse
    #
    [Core::Actions, Core::ScriptHandling, Rules::Terse].each do |mod|
      # make these available both as regular and class methods
      include mod
      singleton_class.include mod
      public_class_method(*mod.private_instance_methods)
    end

    class << self
      # @!visibility private
      attr_reader :debouncers
    end

    @debouncers = java.util.concurrent.ConcurrentHashMap.new

    module_function :items, :things

    module_function

    # @!group Rule Creation

    # (see Rules::Builder#rule)
    def rule(name = nil, id: nil, **kwargs, &block)
      rules.build { rule(name, id:, **kwargs, &block) }
    end

    # Creates a rule that will remove existing rules with the same id, even when the id has been inferred.
    # @see rule
    def rule!(name = nil, id: nil, **kwargs, &block)
      rules.build { rule(name, id:, replace: true, **kwargs, &block) }
    end

    # (see Rules::Builder#scene)
    def scene(name = nil, description: nil, id: nil, tag: nil, tags: nil, **kwargs, &block)
      rules.build { scene(name, description:, id:, tag:, tags:, **kwargs, &block) }
    end

    # Creates a scene that will remove existing rules/scenes with the same id, even when the id has been inferred.
    # @see scene
    def scene!(name = nil, description: nil, id: nil, tag: nil, tags: nil, **kwargs, &block)
      rules.build do
        scene(name, description:, id:, tag:, tags:, replace: true, **kwargs, &block)
      end
    end

    # (see Rules::Builder#script)
    def script(name = nil, description: nil, id: nil, tag: nil, tags: nil, **kwargs, &block)
      rules.build { script(name, description:, id:, tag:, tags:, **kwargs, &block) }
    end

    # Creates a script that will remove existing rules/scripts with the same id, even when the id has been inferred.
    # @see script
    def script!(name = nil, description: nil, id: nil, tag: nil, tags: nil, **kwargs, &block)
      rules.build do
        script(name, description:, id:, tag:, tags:, replace: true, **kwargs, &block)
      end
    end

    # @!group Rule Support

    # rubocop:disable Layout/LineLength

    #
    # Defines a new profile that can be applied to item channel links.
    #
    # To create a profile that can be used in the UI, provide a label and optionally a {config_description},
    # otherwise the profile will not be visible in the UI.
    #
    # @param [String, Symbol] id The id for the profile.
    # @param [String, nil] label The label for the profile. When nil, the profile will not be visible in the UI.
    # @param [:state, :trigger] type The type of profile.
    # @param [org.openhab.core.config.core.ConfigDescription, nil] config_description
    #   The configuration description for the profile so that it can be configured in the UI.
    # @yield [event, command: nil, state: nil, trigger: nil, time_series: nil, callback:, link:, item:, channel_uid:, configuration:, context:]
    #   All keyword params are optional. Any that aren't defined won't be passed.
    # @yieldparam [:command_from_item, :state_from_item, :command_from_handler, :state_from_handler, :time_series_from_handler, :trigger_from_handler] event
    #   The event that needs to be processed.
    # @yieldparam [Command, nil] command
    #   The command being sent for `:command_from_item` and `:command_from_handler` events.
    # @yieldparam [State, nil] state
    #   The state being sent for `:state_from_item` and `:state_from_handler` events.
    # @yieldparam [String] trigger
    #   The event being sent for `:trigger_from_handler` events.
    # @yieldparam [TimeSeries] time_series
    #   The time series for `:time_series_from_handler` events.
    #   Only available since openHAB 4.1.
    # @yieldparam [Core::Things::ProfileCallback] callback
    #   The callback to be used to customize the action taken.
    # @yieldparam [Core::Things::ItemChannelLink] link
    #   The link between the item and the channel, including its configuration.
    # @yieldparam [Item] item The linked item.
    # @yieldparam [Core::Things::ChannelUID] channel_uid The linked channel.
    # @yieldparam [Hash] configuration The profile configuration.
    # @yieldparam [org.openhab.core.thing.profiles.ProfileContext] context The profile context.
    # @yieldparam [String, nil] source The source of the event.
    #   @since openHAB 5.1
    # @yieldreturn [Boolean] Return true from the block in order to have default processing.
    # @return [void]
    #
    # @see org.openhab.core.thing.profiles.Profile
    # @see org.openhab.core.thing.profiles.StateProfile
    # @see org.openhab.core.thing.profiles.TimeSeriesProfile
    # @see org.openhab.core.thing.profiles.TriggerProfile
    #
    # @example Vetoing a command
    #   profile(:veto_closing_shades) do |event, item:, command:|
    #     next false if command&.down?
    #
    #     true
    #   end
    #
    #   items.build do
    #     rollershutter_item "MyShade" do
    #       channel "thing:rollershutter", profile: "ruby:veto_closing_shades"
    #     end
    #   end
    #   # can also be referenced from an `.items` file:
    #   # Rollershutter MyShade { channel="thing:rollershutter"[profile="ruby:veto_closing_shades"] }
    #
    # @example Overriding units from a binding
    #   profile(:set_uom) do |event, callback:, configuration:, state:, command:|
    #     unless configuration["unit"]
    #       logger.warn("Unit configuration not provided for set_uom profile")
    #       next true
    #     end
    #
    #     case event
    #     when :state_from_handler
    #       next true unless state.is_a?(DecimalType) || state.is_a?(QuantityType) # what is it then?!
    #
    #       state = state.to_d if state.is_a?(QuantityType) # ignore the units if QuantityType was given
    #       callback.send_update(state | configuration["unit"])
    #       false
    #     when :command_from_item
    #       # strip the unit from the command, as the binding likely can't handle it
    #       next true unless command.is_a?(QuantityType)
    #
    #       callback.handle_command(DecimalType.new(command.to_d))
    #       false
    #     else
    #       true # pass other events through as normal
    #     end
    #   end
    #   # can also be referenced from an `.items` file:
    #   # Number:Temperature MyTempWithNonUnitValueFromBinding "I prefer Celsius [%d °C]" { channel="something_that_returns_F"[profile="ruby:set_uom", unit="°F"] }
    #
    # @example Create a profile that is usable in the UI
    #   config_description = config_description do
    #     parameter :min, :decimal, label: "Minimum", description: "Minimum value"
    #     parameter :max, :decimal, label: "Maximum", description: "Maximum value"
    #   end
    #
    #   profile(:range_filter, label: "Range Filter", config_description: config_description) do |event, state:, configuration:|
    #     next true unless event == :state_from_handler
    #
    #     (configuration["min"]..configuration["max"]).cover?(state)
    #   end
    #
    def profile(id, label: nil, type: :state, config_description: nil, &block)
      raise ArgumentError, "Block is required" unless block

      id = id.to_s

      ThreadLocal.thread_local(openhab_rule_type: "profile", openhab_rule_uid: id) do
        Core::ProfileFactory.instance.register(id, block, label:, type:, config_description:)
      end
    end

    #
    # Create a {org.openhab.core.config.core.ConfigDescription ConfigDescription} object.
    #
    # @param [String, java.net.URI] uri The URI for the ConfigDescription. When nil, a dummy URI is used which will
    #   be replaced by the profile with the correct URI for that profile.
    # @yield Block that consists of {ConfigDescription::Builder#parameter} and {ConfigDescription::Builder#group} calls.
    #
    # @return [org.openhab.core.config.core.ConfigDescription]
    #   The created {org.openhab.core.config.core.ConfigDescription ConfigDescription} object
    #
    # @example
    #  config_description = config_description do
    #    parameter :ungrouped_parameter, :decimal, label: "Ungrouped Parameter", min: 1, max: 5
    #
    #    group "Config Group", label: "Grouped parameters", advanced: true do
    #      parameter :my_parameter, :string, label: "My Parameter", description: "My Parameter Description"
    #      parameter :other_parameter, :integer, label: "Other Parameter", description: "Other Parameter Description"
    #    end
    #  end
    #
    def config_description(uri = nil, &block)
      raise ArgumentError, "Block is required" unless block

      ConfigDescription::Builder.new.build(uri, &block)
    end

    # rubocop:enable Layout/LineLength

    # @!group Object Access

    # @!parse
    #   # (see Core::EntityLookup#items)
    #   def items; end
    #
    #   # (see Core::EntityLookup#things)
    #   def things; end

    #
    # (see Core::ValueCache)
    #
    # @return [Core::ValueCache] the cache shared among all scripts and UI rules in all languages.
    #
    # @see Core::ValueCache ValueCache
    #
    def shared_cache
      $sharedCache
    end

    #
    # Fetches all rules from the rule registry.
    #
    # @return [Core::Rules::Registry]
    #
    def rules
      Core::Rules::Registry.instance
    end

    # @return [Core::Sitemaps::Provider]
    def sitemaps
      Core::Sitemaps::Provider.instance
    end

    #
    # Provides access to timers created by {after after}
    #
    # @return [TimerManager]
    def timers
      TimerManager.instance
    end

    # @!group Utilities

    #
    # Create a timer and execute the supplied block after the specified duration
    #
    # ### Reentrant Timers
    #
    # Timers with an id are reentrant by id. Reentrant means that when the same id is encountered,
    # the timer is rescheduled rather than creating a second new timer. Note that the timer will
    # execute the block provided in the latest call.
    #
    # This removes the need for the usual boilerplate code to manually keep track of timer objects.
    #
    # Timers with `id` can be managed with the built-in {timers} object.
    #
    # When a timer is cancelled, it will be removed from the object.
    #
    # Be sure that your ids are unique. For example, if you're using {Item items} as your
    # ids, you either need to be sure you don't use the same item for multiple logical contexts,
    # or you need to make your id more specific, by doing something like embedding the item in
    # array with a symbol of the timer's purpose, like `[:vacancy, item]`. But also note that
    # assuming default settings, every Ruby file (for file-based rules) or UI rule gets its
    # own instance of the timers object, so you don't need to worry about collisions among
    # different files.
    #
    # ### Sharing Timers with other scripts
    #
    # When a timer is stored in the {shared_cache}, it will automatically be converted into
    # an openHAB Timer object. It can then be used in other scripts or UI rules,
    # written in JRuby or other supported languages.
    #
    # Timers are normally managed by TimerManager, and are normally automatically cancelled
    # when the script unloads/reloads.
    # To disable this automatic timer cancellation at script unload, call {Core::Timer#unmanage}.
    #
    # openHAB will cancel the timer stored in the {OpenHAB::DSL.shared_cache shared_cache}
    # and remove the cache entry when all the scripts that _had accessed_ it have been unloaded.
    #
    # @see timers
    # @see Rules::BuilderDSL#changed
    # @see Items::TimedCommand
    #
    # @param [java.time.temporal.TemporalAmount, #to_zoned_date_time, Proc] duration
    #   Duration after which to execute the block
    # @param [Object] id ID to associate with timer. The timer can be managed via {timers}.
    # @param [true,false] reschedule Reschedule the timer if it already exists.
    # @yield Block to execute when the timer is elapsed.
    # @yieldparam [Core::Timer] timer
    #
    # @return [Core::Timer] if `reschedule` is false, the existing timer.
    #   Otherwise the new timer.
    #
    # @example Create a simple timer
    #   after 5.seconds do
    #     logger.info("Timer Fired")
    #   end
    #
    # @example Timers delegate methods to openHAB timer objects
    #   after 1.second do |timer|
    #     logger.info("Timer is active? #{timer.active?}")
    #   end
    #
    # @example Timers can be rescheduled to run again, waiting the original duration
    #   after 3.seconds do |timer|
    #     logger.info("Timer Fired")
    #     timer.reschedule
    #   end
    #
    # @example Timers can be rescheduled for different durations
    #   after 3.seconds do |timer|
    #     logger.info("Timer Fired")
    #     timer.reschedule 5.seconds
    #   end
    #
    # @example Timers can be manipulated through the returned object
    #   mytimer = after 1.minute do
    #     logger.info("It has been 1 minute")
    #   end
    #
    #   mytimer.cancel
    #
    # @example Reentrant timers will automatically reschedule if the same id is encountered again
    #   rule "Turn off closet light after 10 minutes" do
    #     changed ClosetLights.members, to: ON
    #     triggered do |item|
    #       after 10.minutes, id: item do
    #         item.ensure.off
    #       end
    #     end
    #   end
    #
    # @example Timers with id can be managed through the built-in `timers` object
    #   after 1.minute, id: :foo do
    #     logger.info("managed timer has fired")
    #   end
    #
    #   timers.cancel(:foo)
    #
    #   if timers.include?(:foo)
    #     logger.info("The timer :foo is not active")
    #   end
    #
    # @example Only create a new timer if it isn't already scheduled
    #   after(1.minute, id: :foo, reschedule: false) do
    #     logger.info("Timer fired")
    #   end
    #
    # @example Reentrant timers will execute the block from the most recent call
    #   # In the following example, if Item1 received a command, followed by Item2,
    #   # the timer will execute the block referring to Item2.
    #   rule "Execute The Most Recent Block" do
    #     received_command Item1, Item2
    #     run do |event|
    #       after(10.minutes, id: :common_timer) do
    #         logger.info "The latest command was received from #{event.item}"
    #       end
    #     end
    #   end
    #
    # @example Timers can be shared with other scripts
    #   # script1.rb:
    #   timer = after(10.hours) { logger.warn "Timer created in script1.rb fired" }
    #   shared_cache[:script1_timer] = timer
    #
    #   # inside a different JRuby UI rule or script:
    #   # This is an openHAB timer object, not a JRuby timer object
    #   # the reschedule method expects a ZonedDateTime
    #   shared_cache[:script1_timer]&.reschedule(10.seconds.from_now)
    #
    #   # inside another JS script:
    #   cache.shared.get("script1_timer")?.cancel()
    #
    def after(duration, id: nil, reschedule: true, &block)
      raise ArgumentError, "Block is required" unless block

      # Carry rule name to timer
      thread_locals = ThreadLocal.persist
      timers.create(duration, id:, reschedule:, thread_locals:, block:)
    end

    #
    # Convert a string based range into a range of LocalTime, LocalDate, MonthDay, or ZonedDateTime
    # depending on the format of the string.
    #
    # @return [Range] converted range object
    #
    # @example Range#cover?
    #   logger.info("Within month-day range") if between('02-20'..'06-01').cover?(MonthDay.now)
    #
    # @example Use in a Case
    #   case MonthDay.now
    #   when between('01-01'..'03-31')
    #     logger.info("First quarter")
    #   when between('04-01'..'06-30')
    #    logger.info("Second quarter")
    #   end
    #
    # @example Create a time range
    #   between('7am'..'12pm').cover?(LocalTime.now)
    #
    # @see CoreExt::Between#between? #between?
    #
    def between(range)
      raise ArgumentError, "Supplied object must be a range" unless range.is_a?(Range)

      start = try_parse_time_like(range.begin)
      finish = try_parse_time_like(range.end)
      Range.new(start, finish, range.exclude_end?)
    end

    #
    # Limits the frequency of calls to the given block within a given amount of time.
    #
    # It can be useful to throttle certain actions even when a rule is triggered too often.
    # This can be used to debounce triggers in a UI rule.
    #
    # @param (see Debouncer#initialize)
    # @param [Object] id ID to associate with this debouncer.
    # @param [Block] block The block to be debounced.
    #
    # @return [void]
    #
    # @example Run at most once per second even when being called more frequently
    #   (1..100).each do
    #     debounce for: 1.second do
    #       logger.info "This will not be logged more frequently than every 1 second"
    #     end
    #     sleep 0.1
    #   end
    #
    # @see Debouncer Debouncer class
    # @see Rules::BuilderDSL#debounce debounce rule guard
    #
    # @!visibility private
    def debounce(for:, leading: false, idle_time: nil, id: nil, &block)
      interval = binding.local_variable_get(:for)
      id ||= block.source_location
      DSL.debouncers.compute(id) do |_key, debouncer|
        debouncer ||= Debouncer.new(for: interval, leading:, idle_time:)
        debouncer.call(&block)
        debouncer
      end
    end

    #
    # Waits until calls to this method have stopped firing for a period of time
    # before executing the block.
    #
    # This method acts as a guard for the given block to ensure that it doesn't get executed
    # too frequently. The debounce_for method can be called as frequently as possible.
    # The given block, however, will only be executed once the `debounce_time` has passed
    # since the last call to debounce_for.
    #
    # This method can be used from within a UI rule as well as from a file-based rule.
    #
    # @param (see Rules::BuilderDSL#debounce_for)
    # @param [Object] id ID to associate with this call.
    # @param [Block] block The block to be debounced.
    #
    # @return [void]
    #
    # @example Run a block of code only after an item has stopped changing
    #   # This can be placed inside a UI rule with an Item Change trigger for
    #   # a Door contact sensor.
    #   # If the door state has stopped changing state for 10 minutes,
    #   # execute the block.
    #   debounce_for(10.minutes) do
    #     if DoorState.open?
    #       Voice.say("The door has been left open!")
    #     end
    #   end
    #
    # @see Rules::BuilderDSL#debounce_for Rule builder's debounce_for for a detailed description
    #
    def debounce_for(debounce_time, id: nil, &block)
      idle_time = debounce_time.is_a?(Range) ? debounce_time.begin : debounce_time
      debounce(for: debounce_time, idle_time:, id:, &block)
    end

    #
    # Rate-limits block executions by delaying calls and only executing the last
    # call within the given duration.
    #
    # When throttle_for is called, it will hold from executing the block and start
    # a fixed timer for the given duration. Should more calls occur during
    # this time, keep holding and once the wait time is over, execute the block.
    #
    # {throttle_for} will execute the block after it had waited for the given duration,
    # regardless of how frequently `throttle_for` was called.
    # In contrast, {debounce_for} will wait until there is a minimum interval
    # between two triggers.
    #
    # {throttle_for} is ideal in situations where regular status updates need to be made
    # for frequently changing values. It is also useful when a rule responds to triggers
    # from multiple related items that are updated at around the same time. Instead of
    # executing the rule multiple times, {throttle_for} will wait for a pre-set amount
    # of time since the first group of triggers occurred before executing the rule.
    #
    # @param (see Rules::BuilderDSL#throttle_for)
    # @param [Object] id ID to associate with this call.
    # @param [Block] block The block to be throttled.
    #
    # @return [void]
    #
    # @see Rules::BuilderDSL#debounce_for Rule builder's debounce_for for a detailed description
    # @see Rules::BuilderDSL#throttle_for
    #
    def throttle_for(duration, id: nil, &block)
      debounce(for: duration, id:, &block)
    end

    # (see Core::Actions::Transformation.transform)
    def transform(type, function, value)
      Transformation.transform(type, function, value)
    end

    #
    # Limit how often the given block executes to the specified interval.
    #
    # {only_every} will execute the given block but prevents further executions
    # until the given interval has passed. In contrast, {throttle_for} will not
    # execute the block immediately, and will wait until the end of the interval.
    #
    # @param (see Rules::BuilderDSL#only_every)
    # @param [Object] id ID to associate with this call.
    # @param [Block] block The block to be throttled.
    #
    # @return [void]
    #
    # @example Prevent door bell from ringing repeatedly
    #   # This can be called from a UI rule.
    #   # For file based rule, use the `only_every` rule guard
    #   only_every(30.seconds) { Audio.play_sound("doorbell.mp3") }
    #
    # @see Rules::BuilderDSL#debounce_for Rule builder's debounce_for for a detailed description
    # @see Rules::BuilderDSL#only_every
    #
    def only_every(interval, id: nil, &block)
      interval = 1.send(interval) if %i[second minute hour day].include?(interval)
      debounce(for: interval, leading: true, id:, &block)
    end

    #
    # Store states of supplied items
    #
    # Takes one or more items and returns a map `{Item => State}` with the
    # current state of each item. It is implemented by calling openHAB's
    # [events.storeStates()](https://www.openhab.org/docs/configuration/actions.html#event-bus-actions).
    #
    # @param [Item] items Items to store states of.
    #
    # @return [Core::Items::StateStorage] item states
    #
    # @example
    #   states = store_states Item1, Item2
    #   ...
    #   states.restore
    #
    # @example With a block
    #   store_states Item1, Item2 do
    #     ...
    #   end # the states will be restored here
    #
    def store_states(*items)
      states = Core::Items::StateStorage.from_items(*items)
      if block_given?
        yield
        states.restore
      end
      states
    end

    #
    # @!group Block Modifiers
    #   These methods allow certain operations to be grouped inside the given block
    #   to reduce repetitions
    #

    #
    # Permanently enable conditional execution of commands and updates for the current thread.
    #
    # When conditional executions are enabled, commands and updates will only be sent if the
    # item's current state is not the same as the command or updated state.
    # This eliminates the need to chain the command and update calls through
    # {DSL::Items::Ensure::Ensurable#ensure ensure}.
    #
    # When conditional executions are enabled either by this method or within a block of {ensure_states},
    # commands and updates can still be forcefully executed using the corresponding bang methods, e.g.
    # `Item1.on!`, `Item1.command!(50)`, or `Item1.update!(ON)`.
    #
    # @note This method is only intended for use at the top level of rule
    #   scripts. If it's used within library methods, or hap-hazardly within
    #   rules, things can get very confusing because the prior state won't be
    #   properly restored.
    #
    # @param [Boolean] active Whether to enable or disable conditional executions.
    # @return [Boolean] The previous ensure_states setting.
    #
    # @example Make ensure_states the default for the rest of the script
    #   ensure_states!
    #
    #   # From now, all commands are "ensured", i.e. only sent when the current state is different
    #   Item1.on
    #   Item2.command(ON)
    #
    #   # While ensure_states! is active, we can still forcibly send a command
    #   # regardless of the item's current state
    #   Item2.on!
    #
    # @see ensure_states
    #
    def ensure_states!(active: true)
      old = Thread.current[:openhab_ensure_states]
      Thread.current[:openhab_ensure_states] = active
      old
    end

    #
    # Global method that takes a block and for the duration of the block
    # all commands sent will check if the item is in the command's state
    # before sending the command. This also applies to updates.
    #
    # @yield
    # @return [Object] The result of the block.
    #
    # @example Turn on several switches only if they're not already on
    #   ensure_states do
    #     Switch1.on
    #     Switch2.on
    #   end
    #
    # @example
    #   # VirtualSwitch is in state `ON`
    #   ensure_states do
    #     VirtualSwitch << ON       # No command will be sent
    #     VirtualSwitch.update(ON)  # No update will be posted
    #     VirtualSwitch << OFF      # Off command will be sent
    #     VirtualSwitch.update(OFF) # No update will be posted
    #   end
    #
    # @example
    #   ensure_states do
    #     rule 'Items in an execution block will have ensure_states applied to them' do
    #       changed VirtualSwitch
    #       run do
    #         VirtualSwitch.on
    #         VirtualSwitch2.on
    #       end
    #     end
    #   end
    #
    # @example
    #   rule 'ensure_states must be in an execution block' do
    #     changed VirtualSwitch
    #     run do
    #        ensure_states do
    #           VirtualSwitch.on
    #           VirtualSwitch2.on
    #        end
    #     end
    #   end
    #
    def ensure_states
      old = ensure_states!
      yield
    ensure
      ensure_states!(active: old)
    end

    #
    # Sets a thread local variable to set the default persistence service
    # for method calls inside the block
    #
    # @example
    #   persistence(:influxdb) do
    #     Item1.persist
    #     Item1.changed_since(1.hour)
    #     Item1.average_since(12.hours)
    #   end
    #
    # @param [Object] service Persistence service either as a String or a Symbol
    # @yield [] Block executed in context of the supplied persistence service
    # @return [Object] The return value from the block.
    #
    # @see persistence!
    # @see OpenHAB::Core::Items::Persistence
    #
    def persistence(service)
      old = persistence!(service)
      yield
    ensure
      persistence!(old)
    end

    #
    # Permanently sets the default persistence service for the current thread
    #
    # @note This method is only intended for use at the top level of rule
    #   scripts. If it's used within library methods, or hap-hazardly within
    #   rules, things can get very confusing because the prior state won't be
    #   properly restored.
    #
    # @param [Object] service Persistence service either as a String or a Symbol. When nil, use
    #   the system's default persistence service.
    # @return [Object,nil] The previous persistence service settings, or nil when using the system's default.
    #
    # @see persistence
    # @see OpenHAB::Core::Items::Persistence
    #
    def persistence!(service = nil)
      old = Thread.current[:openhab_persistence_service]
      Thread.current[:openhab_persistence_service] = service
      old
    end

    #
    # Sets the implicit unit(s) for operations inside the block.
    #
    # @yield
    #
    # @overload unit(*units)
    #   Sets the implicit unit(s) for this thread such that classes
    #   operating inside the block can perform automatic conversions to the
    #   supplied unit for {QuantityType}.
    #
    #   To facilitate conversion of multiple dimensioned and dimensionless
    #   numbers the unit block may be used. The unit block attempts to do the
    #   _right thing_ based on the mix of dimensioned and dimensionless items
    #   within the block. Specifically all dimensionless items are converted to
    #   the supplied unit, except when they are used for multiplication or
    #   division.
    #
    #   @param [String, javax.measure.Unit] units
    #     Unit or String representing unit
    #   @yield [] The block will be executed in the context of the specified unit(s).
    #   @return [Object] the result of the block
    #
    #   @example Arithmetic Operations Between QuantityType and Numeric
    #     # Number:Temperature NumberC = 23 °C
    #     # Number:Temperature NumberF = 70 °F
    #     # Number Dimensionless = 2
    #     unit('°F') { NumberC.state - NumberF.state < 4 }                                      # => true
    #     unit('°F') { NumberC.state - 24 | '°C' < 4 }                                          # => true
    #     unit('°F') { (24 | '°C') - NumberC.state < 4 }                                        # => true
    #     unit('°C') { NumberF.state - 20 < 2 }                                                 # => true
    #     unit('°C') { NumberF.state - Dimensionless.state }                                    # => 19.11 °C
    #     unit('°C') { NumberF.state - Dimensionless.state < 20 }                               # => true
    #     unit('°C') { Dimensionless.state + NumberC.state == 25 }                              # => true
    #     unit('°C') { 2 + NumberC.state == 25 }                                                # => true
    #     unit('°C') { Dimensionless.state * NumberC.state == 46 }                              # => true
    #     unit('°C') { 2 * NumberC.state == 46 }                                                # => true
    #     unit('°C') { ( (2 * (NumberF.state + NumberC.state) ) / Dimensionless.state ) < 45 }  # => true
    #     unit('°C') { [NumberC.state, NumberF.state, Dimensionless.state].min }                # => 2
    #
    #   @example Commands and Updates inside a unit block
    #     unit('°F') { NumberC << 32 }; NumberC.state                                           # => 0 °C
    #     # Equivalent to
    #     NumberC << "32 °F"
    #     # or
    #     NumberC << 32 | "°F"
    #
    #   @example Specifying Multiple Units
    #     unit("°C", "kW") do
    #       TemperatureItem.update("50 °F")
    #       TemperatureItem.state < 20          # => true. TemperatureItem.state < 20 °C
    #       PowerUsage.update("3000 W")
    #       PowerUsage.state < 10               # => true. PowerUsage.state < 10 kW
    #     end
    #
    # @overload unit(dimension)
    #   @param [javax.measure.Dimension] dimension The dimension to fetch the unit for.
    #   @return [javax.measure.Unit] The current unit for the thread of the specified dimensions
    #
    #   @example
    #     unit(SIUnits::METRE.dimension) # => ImperialUnits::FOOT
    #
    def unit(*units)
      if units.length == 1 && units.first.is_a?(javax.measure.Dimension)
        return Thread.current[:openhab_units]&.[](units.first)
      end

      raise ArgumentError, "You must give a block to set the unit for the duration of" unless block_given?

      begin
        old_units = unit!(*units)
        yield
      ensure
        Thread.current[:openhab_units] = old_units
      end
    end

    #
    # Permanently sets the implicit unit(s) for this thread
    #
    # @note This method is only intended for use at the top level of rule
    #   scripts. If it's used within library methods, or hap-hazardly within
    #   rules, things can get very confusing because the prior state won't be
    #   properly restored.
    #
    # {unit!} calls are cumulative - additional calls will not erase the effects
    # of previous calls unless they are for the same dimension.
    #
    # @return [Hash<javax.measure.Dimension=>javax.measure.Unit>]
    #   the prior unit configuration
    #
    # @overload unit!(*units)
    #   @param [String, javax.measure.Unit] units
    #     Unit or String representing unit.
    #
    #   @example Set several defaults at once
    #     unit!("°F", "ft", "lbs")
    #     (50 | "°F") == 50 # => true
    #
    #   @example Calls are cumulative
    #     unit!("°F")
    #     unit!("ft")
    #     (50 | "°F") == 50 # => true
    #     (2 | "yd") == 6 # => true
    #
    #   @example Subsequent calls override the same dimension from previous calls
    #     unit!("yd")
    #     unit!("ft")
    #     (2 | "yd") == 6 # => true
    #
    # @overload unit!
    #   Clear all unit settings
    #
    #   @example Clear all unit settings
    #     unit!("ft")
    #     unit!
    #     (2 | "yd") == 6 # => false
    #
    def unit!(*units)
      units = units.each_with_object({}) do |unit, r|
        unit = org.openhab.core.types.util.UnitUtils.parse_unit(unit) if unit.is_a?(String)
        r[unit.dimension] = unit
      end

      old_units = Thread.current[:openhab_units] || {}
      Thread.current[:openhab_units] = units.empty? ? {} : old_units.merge(units)
      old_units
    end

    #
    # Sets the implicit provider(s) for operations inside the block.
    #
    # @param (see #provider!)
    # @yield [] The block will be executed using the specified provider(s).
    # @return [Object] the result of the block
    #
    # @example
    #   provider(metadata: :persistent) do
    #     Switch1.metadata[:last_status_from_service] = status
    #   end
    #
    #   provider!(metadata: { last_status_from_service: :persistent }, Switch2: :persistent)
    #   Switch1.metadata[:last_status_from_service] = status # this will persist in JSONDB
    #   Switch1.metadata[:homekit] = "Lightbulb" # this will be removed when the script is deleted
    #   Switch2.metadata[:homekit] = "Lightbulb" # this will persist in JSONDB
    #
    # @see provider!
    # @see OpenHAB::Core::Provider.current Provider.current for how the current provider is calculated
    #
    def provider(*providers, **providers_by_type)
      raise ArgumentError, "You must give a block to set the provider for the duration of" unless block_given?

      begin
        old_providers = provider!(*providers, **providers_by_type)
        yield
      ensure
        Thread.current[:openhab_providers] = old_providers
      end
    end

    #
    # Permanently set the implicit provider(s) for this thread.
    #
    # @note This method is only intended for use at the top level of rule
    #   scripts. If it's used within library methods, or hap-hazardly within
    #   rules, things can get very confusing because the prior state won't be
    #   properly restored.
    #
    # {provider!} calls are cumulative - additional calls will not erase the effects
    # of previous calls unless they are for the same provider type.
    #
    # @overload provider!(things: nil, items: nil, metadata: nil, links: nil, **metadata_items)
    #
    # @param [Core::Provider, org.openhab.core.common.registry.ManagedProvider, :persistent, :transient, Proc] providers
    #   An explicit provider to use. If it's a {Core::Provider}, the type will be inferred automatically.
    #   Otherwise it's applied to all types.
    # @param [Hash] providers_by_type
    #     A list of providers by type. Type can be `:items`, `:metadata`, `:things`, `:links`,
    #     an {Item} applying the provider to all metadata on that item, or a String or Symbol
    #     applying the provider to all metadata of that namespace.
    #
    #     The provider can be a {org.openhab.core.common.registry.Provider Provider}, `:persistent`,
    #     `:transient`, or a Proc returning one of those types. When the Proc is called for metadata
    #     elements, the {Core::Items::Metadata::Hash} will be passed as an argument. Therefore it's
    #     recommended that you use a Proc, not a Lambda, for permissive argument matching.
    #
    # @return [Hash] the prior provider configuration.
    #
    # @see provider
    # @see OpenHAB::Core::Provider.current Provider.current for how the current provider is calculated
    #
    def provider!(*providers, **providers_by_type)
      thread_providers = Thread.current[:openhab_providers] ||= {}
      old_providers = thread_providers.dup

      providers.each do |provider|
        case provider
        when Core::Provider
          thread_providers[provider.class.type] = provider
        when org.openhab.core.common.registry.ManagedProvider
          type = provider.type
          unless type
            raise ArgumentError, "#{provider.inspect} is for objects which are not supported by openhab-scripting"
          end

          thread_providers[type] = provider
        when Proc,
          :transient,
          :persistent
          Core::Provider::KNOWN_TYPES.each do |known_type|
            thread_providers[known_type] = provider
          end
        when Hash
          # non-symbols can't be used as kwargs, so Item keys show up as a separate hash here
          # just merge it in, and allow it to be handled below
          providers_by_type.merge!(provider)
        else
          raise ArgumentError, "#{provider.inspect} is not a valid provider"
        end
      end

      providers_by_type.each do |type, provider|
        case provider
        when Proc,
          org.openhab.core.common.registry.ManagedProvider,
          :transient,
          :persistent,
          nil
          nil
        else
          raise ArgumentError, "#{provider.inspect} is not a valid provider"
        end

        case type
        when :items, :metadata, :things, :links
          if provider.is_a?(org.openhab.core.common.registry.ManagedProvider) && provider.type != type
            raise ArgumentError, "#{provider.inspect} is not a provider for #{type}"
          end

          thread_providers[type] = provider
        when Symbol, String
          (thread_providers[:metadata_namespaces] ||= {})[type.to_s] = provider
        when Item
          (thread_providers[:metadata_items] ||= {})[type.name] = provider
        else
          raise ArgumentError, "#{type.inspect} is not provider type"
        end
      end

      old_providers
    end

    #
    # @see CoreExt::Ephemeris
    #
    # @overload holiday_file(file)
    #
    #   Sets a thread local variable to use a specific holiday file
    #   for {CoreExt::Ephemeris ephemeris calls} inside the block.
    #
    #   @param [String, nil] file Path to a file defining holidays;
    #     `nil` to reset to default.
    #   @yield [] Block executed in context of the supplied holiday file
    #   @return [Object] The return value from the block.
    #
    #   @example Set a specific holiday configuration file temporarily
    #     holiday_file("/home/cody/holidays.xml") do
    #       Time.now.next_holiday
    #     end
    #
    #   @see holiday_file!
    #
    # @overload holiday_file
    #
    #   Returns the current thread local value for the holiday file.
    #
    #   @return [String, nil] the current holiday file
    #
    def holiday_file(*args)
      raise ArgumentError, "wrong number of arguments (given #{args.length}, expected 0..1)" if args.length > 1

      old = Thread.current[:openhab_holiday_file]
      return old if args.empty?

      holiday_file!(args.first)
      yield
    ensure
      holiday_file!(old)
    end

    #
    # Sets a thread local variable to set the default holiday file.
    #
    # @see https://github.com/svendiedrichsen/jollyday/tree/master/src/main/resources/holidays Example data files from the source
    #
    # @example
    #   holiday_file!("/home/cody/holidays.xml")
    #   Time.now.next_holiday
    #
    # @param [String, nil] file Path to a file defining holidays;
    #   `nil` to reset to default.
    # @return [Symbol, nil] the new holiday file
    #
    def holiday_file!(file = nil)
      Thread.current[:openhab_holiday_file] = file
    end

    #
    # @param [String] string Date/time string to parse.
    #   The string can be in any format recognized by:
    #   - {OpenHAB::CoreExt::Java::LocalTime.parse LocalTime.parse}
    #   - {OpenHAB::CoreExt::Java::LocalDate.parse LocalDate.parse}
    #   - {OpenHAB::CoreExt::Java::MonthDay.parse MonthDay.parse}, e.g. "12-25"
    #   - {OpenHAB::CoreExt::Java::ZonedDateTime.parse ZonedDateTime.parse}
    #   - [Time.parse](https://rubyapi.org/o/time#method-c-parse), e.g. "2021-01-01 12:00:", or "3:30pm"
    # @return [LocalTime, LocalDate, MonthDay, ZonedDateTime, Time] the parsed date/time
    #
    # @!visibility private
    def try_parse_time_like(string)
      return string unless string.is_a?(String)

      exception = nil
      [java.time.LocalTime, java.time.LocalDate, java.time.MonthDay, java.time.ZonedDateTime, Time].each do |klass|
        return klass.parse(string)
      rescue ArgumentError => e
        exception ||= e
        next
      end

      raise exception
    end

    #
    # Provide access to the script context / variables
    # see OpenHAB::DSL::Rules::AutomationRule#execute!
    #
    # @!visibility private
    def method_missing(method, *args)
      return super unless args.empty? && !block_given?

      if (context = Thread.current[:openhab_context]) && context.key?(method)
        logger.trace { "DSL#method_missing found context variable: '#{method}'" }
        return context[method]
      elsif Core.ui_context&.key?(method)
        logger.trace { "DSL#method_missing found UI context variable: '#{method}'" }
        return Core.ui_context[method]
      end
      super
    end

    # @!visibility private
    def respond_to_missing?(method, include_private = false)
      Thread.current[:openhab_context]&.key?(method) || Core.ui_context&.key?(method) || super
    end
  end
end

OpenHAB::Core.wait_till_openhab_ready

# import Items classes into global namespace
OpenHAB::Core::Items.import_into_global_namespace

# Extend `main` with DSL methods
singleton_class.include(OpenHAB::DSL)
# Patch Object to work around https://github.com/openhab/openhab-jruby/issues/4
Object.extend(OpenHAB::CoreExt::Ruby::Object::ClassMethods)

logger.debug { "openHAB JRuby Scripting Library Version #{OpenHAB::DSL::VERSION} Loaded" }

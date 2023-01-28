# frozen_string_literal: true

Dir[File.expand_path("types/*.rb", __dir__)].sort.each do |f|
  require f
end

module OpenHAB
  module Core
    #
    # Contains the core types that openHAB uses as {State}s for items, and
    # {Command}s to be sent to control them.
    #
    # Types are the specific data types that commands and states are. They can be
    # sent to items, be the current state of an item, or be the `command`, `state`,
    # and `was` field of various
    # {group::OpenHAB::DSL::Rules::BuilderDSL::Triggers triggers}.
    # Some types have additional useful methods.
    #
    module Types
      # Hash taking a Enum value, and returning two symbols of
      # predicates to be defined for it. the first is the "command" form,
      # which should be defined on ItemCommandEvent, and on the Type itself.
      # the second is "state" form, which should be defined on the applicable
      # Item, and on the Type itself.
      # @!visibility private
      PREDICATE_ALIASES = Hash.new { |_h, k| [:"#{k.downcase}?"] * 2 }
                              .merge({
                                       "PLAY" => %i[play? playing?],
                                       "PAUSE" => %i[pause? paused?],
                                       "REWIND" => %i[rewind? rewinding?],
                                       "FASTFORWARD" => %i[fast_forward? fast_forwarding?]
                                     }).freeze

      # Hash taking a Enum value, and returning an array of symbols
      # of the command to define for it
      # @!visibility private
      COMMAND_ALIASES = Hash.new { |_h, k| k.downcase.to_sym }
                            .merge({
                                     "FASTFORWARD" => :fast_forward
                                   }).freeze

      constants.map { |c| const_get(c) }
               .grep(Module)
               .select { |k| k < java.lang.Enum }
               .each do |klass|
        # make sure == from Type is inherited
        klass.remove_method(:==)

        # dynamically define predicate methods
        klass.values.each do |value| # rubocop:disable Style/HashEachMethods this isn't a Ruby hash
          # include all the aliases that we define for items both command and
          # state aliases (since types can be interrogated as an incoming
          # command, or as the state of an item)
          command = :"#{Types::COMMAND_ALIASES[value.to_s]}?"
          states = Types::PREDICATE_ALIASES[value.to_s]

          ([command] | states).each do |method|
            logger.trace("Defining #{klass}##{method} for #{value}")
            klass.class_eval <<~RUBY, __FILE__, __LINE__ + 1
              def #{method}                                                 # def on?
                as(#{value.class.java_class.simple_name}).equal?(#{value})  #   as(OnOffType).equal?(ON)
              end                                                           # end
            RUBY
          end

          method = states.last
          Events::ItemState.class_eval <<~RUBY, __FILE__, __LINE__ + 1
            def #{method}                                                            # def on?
              item_state.as(#{value.class.java_class.simple_name}).equal?(#{value})  #   item_state.as(OnOffType).equal?(ON)
            end                                                                      # end
          RUBY

          Events::ItemStateChangedEvent.class_eval <<~RUBY, __FILE__, __LINE__ + 1
            def was_#{method}                                                            # def was_on?
              old_item_state.as(#{value.class.java_class.simple_name}).equal?(#{value})  #   old_item_state.as(OnOffType).equal?(ON)
            end                                                                          # end
          RUBY
        end
      end
    end
  end
end

# frozen_string_literal: true

require_relative "types"

Dir[File.expand_path("items/*.rb", __dir__)].sort.each do |f|
  require f
end

module OpenHAB
  module Core
    #
    # Contains the core types that openHAB uses to represent items.
    # Items have states from the {Types} module.
    #
    # You may use an item or group name anywhere {DSL} (or just {Core::EntityLookup})
    # is available, and it will automatically be loaded.
    #
    module Items
      class << self
        # Imports all of the item classes into the global namespace
        # for convenient access.
        def import_into_global_namespace
          concrete_item_classes.each do |k|
            const_name = k.java_class.simple_name
            Object.const_set(const_name, k) unless Object.const_defined?(const_name)
          end
          Object.const_set(:GenericItem, GenericItem) unless Object.const_defined?(:GenericItem)
          Object.const_set(:Item, Item) unless Object.const_defined?(:Item)
        end

        private

        # takes an array of Type java classes and returns
        # all the Enum values, in a flat array
        def values_for_enums(enums)
          enums.map(&:ruby_class)
               .select { |k| k < java.lang.Enum }
               .flat_map(&:values)
        end

        # define predicates for checking if an item is in one of the Enum states
        def def_predicate_methods(klass)
          values_for_enums(klass.ACCEPTED_DATA_TYPES).each do |state|
            _command_predicate, state_predicate = Types::PREDICATE_ALIASES[state.to_s]
            next if klass.instance_methods.include?(state_predicate)

            logger.trace("Defining #{klass}##{state_predicate} for #{state}")
            klass.class_eval <<~RUBY, __FILE__, __LINE__ + 1
              def #{state_predicate}                                                  # def on?
                raw_state.as(#{state.class.java_class.simple_name}).equal?(#{state})  #   raw_state.as(OnOffType) == ON
              end                                                                     # end
            RUBY
          end
        end

        # define methods for commanding an item to one of the Enum states
        # as well as predicates for if an ItemCommandEvent is one of those commands
        def def_command_methods(klass)
          values_for_enums(klass.ACCEPTED_COMMAND_TYPES).each do |value|
            command = Types::COMMAND_ALIASES[value.to_s]
            next if klass.instance_methods.include?(command)

            logger.trace("Defining #{klass}##{command} for #{value}")
            klass.class_eval <<~RUBY, __FILE__, __LINE__ + 1
              ruby2_keywords def #{command}(*args, &block)  # ruby2_keywords def on(*args, &block)
                command(#{value}, *args, &block)            #   command(ON, *args, &block)
              end                                           # end
            RUBY

            logger.trace("Defining Enumerable##{command} for #{value}")
            Enumerable.class_eval <<~RUBY, __FILE__, __LINE__ + 1
              def #{command}        # def on
                each(&:#{command})  #   each(&:on)
              end                   # end
            RUBY

            # Override the inherited methods from Enumerable and send it to the base_item
            GroupItem.class_eval <<~RUBY, __FILE__, __LINE__ + 1
              def #{command}                 # def on
                method_missing(:#{command})  #   method_missing(:on)
              end                            # end
            RUBY

            logger.trace("Defining ItemCommandEvent##{command}? for #{value}")
            Events::ItemCommandEvent.class_eval <<~RUBY, __FILE__, __LINE__ + 1
              def #{command}?                                                       # def refresh?
                command.as(#{value.class.java_class.simple_name}).equal?(#{value})  #   command.as(RefreshType).equal?(REFRESH)
              end                                                                   # end
            RUBY
          end
        end

        def concrete_item_classes
          constants.map { |c| const_get(c) }
                   .grep(Module)
                   .select { |k| k < GenericItem }
        end
      end

      # sort classes by hierarchy so we define methods on parent classes first
      constants.map { |c| const_get(c) }
               .grep(Module)
               .select { |k| k <= GenericItem && k != GroupItem && k != StringItem }
               .sort { |a, b| (a < b) ? 1 : -1 }
               .each do |klass|
        klass.field_reader :ACCEPTED_COMMAND_TYPES, :ACCEPTED_DATA_TYPES unless klass == GenericItem

        def_predicate_methods(klass)
        def_command_methods(klass)
      end

      prepend_accepted_data_types
    end
  end
end

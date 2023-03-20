# frozen_string_literal: true

module OpenHAB
  module Core
    module Rules
      # @interface
      java_import org.openhab.core.automation.Rule

      #
      # A {Rule} is a chunk of code that can execute when certain conditions are
      # met, enabling the core dynamic functionality of openHAB.
      #
      module Rule
        #
        # @!method visible?
        #   Check if visibility == `VISIBLE`
        #   @return [true,false]
        #

        #
        # @!method hidden?
        #   Check if visibility == `HIDDEN`
        #   @return [true,false]
        #

        #
        # @!method expert?
        #   Check if visibility == `EXPERT`
        #   @return [true,false]
        #

        #
        # @!method initializing?
        #   Check if rule status == `INITIALIZING`
        #   @return [true,false]
        #
        #
        # @!method idle?
        #   Check if rule status == `IDLE`
        #   @return [true,false]
        #
        #
        # @!method running?
        #   Check if rule status == `RUNNING`
        #   @return [true,false]
        #

        Visibility.constants.each do |visibility|
          class_eval <<~RUBY, __FILE__, __LINE__ + 1
            def #{visibility.to_s.downcase}?           # def visibile?
              visibility == Visibility::#{visibility}  #   visibility == Visibility::VISIBLE
            end                                        # end
          RUBY
        end

        RuleStatus.constants.each do |status|
          next if status == :UNINITIALIZED

          class_eval <<~RUBY, __FILE__, __LINE__ + 1
            def #{status.to_s.downcase}?       # def initializing?
              status == RuleStatus::#{status}  #   status == RuleStatus::INITIALIZING
            end                                # end
          RUBY
        end

        #
        # Check if rule status == `UNINITIALIZED`
        #
        # @return [true,false]
        #
        def uninitialized?
          s = status
          s.nil? || s == RuleStatus::UNINITIALIZED
        end

        #
        # Enable the Rule
        #
        # @param [true, false] enabled
        # @return [void]
        #
        def enable(enabled: true)
          Rules.manager.set_enabled(uid, enabled)
        end

        #
        # Disable the Rule
        #
        # @return [void]
        #
        def disable
          enable(enabled: false)
        end

        #
        # Check if the rule's status detail == `DISABLED`
        #
        # @return [true, false]
        #
        def disabled?
          info = status_info
          info.nil? || info.status_detail == RuleStatusDetail::DISABLED
        end

        #
        # @!attribute [r] status
        # @return [RuleStatus, nil]
        #
        def status
          Rules.manager&.get_status(uid)
        end

        #
        # @!attribute [r] status_info
        # @return [RuleStatusInfo, nil]
        #
        def status_info
          Rules.manager&.get_status_info(uid)
        end

        # @return [String]
        def inspect
          r = "#<OpenHAB::Core::Rules::Rule #{uid}"
          r += " #{name.inspect}" if name
          r += " #{visibility}" unless visible?
          r += " #{status || "<detached>"}"
          r += " (#{status_info.status_detail})" if status_info && status_info.status_detail != RuleStatusDetail::NONE
          r += " tags=#{tags.to_a.inspect}" unless tags.empty?
          r += " configuration=#{configuration.properties.to_h}" if configuration && !configuration.properties.empty?
          "#{r}>"
        end

        # @return [String]
        def to_s
          uid
        end

        #
        # Manually trigger the rule
        #
        # @param [Object, nil] event The event to pass to the rule's execution blocks.
        # @return [void]
        #
        def trigger(event = nil)
          Rules.manager.run_now(uid, false, { "event" => event })
        end
      end
    end
  end
end

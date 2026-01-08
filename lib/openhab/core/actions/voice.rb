# frozen_string_literal: true

module OpenHAB
  module Core
    module Actions
      # @see https://www.openhab.org/docs/configuration/multimedia.html#actions-3 Voice Actions
      class Voice
        class << self
          # @!visibility private
          alias_method :raw_say, :say if method_defined?(:say)

          #
          # Say text via openHAB Text-To-Speech service, Voice.say()
          #
          # @param text [String] The text to say
          # @param voice [String] Specify a particular voice to use
          # @param sink [String] Specify a particular sink to output the speech
          # @param volume [PercentType] Specify the volume for the speech
          #
          # @return [void]
          #
          # @example Run the TTS engine and output to the default audio sink.
          #   rule 'Say the time every hour' do
          #     every :hour
          #     run { Voice.say "The time is #{TimeOfDay.now}" }
          #   end
          #
          def say(text, voice: nil, sink: nil, volume: nil)
            volume = PercentType.new(volume) unless volume.is_a?(PercentType) || volume.nil?
            raw_say(text.to_s, voice&.to_s, sink&.to_s, volume)
          end
        end
      end
    end
  end
end

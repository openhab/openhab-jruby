# frozen_string_literal: true

module OpenHAB
  module Core
    module Actions
      # @see https://www.openhab.org/docs/configuration/multimedia.html#actions-2 Audio Actions
      class Audio
        class << self
          #
          # Play an audio file via openHAB sound service, Audio.playSound()
          #
          # @param filename [String] The sound file to play
          # @param sink [String] Specify a particular sink to output the speech
          # @param volume [PercentType] Specify the volume for the speech
          #
          # @return [void]
          #
          # @example Play an audio file
          #   rule 'Play an audio file' do
          #     every :hour
          #     run { Audio.play_sound "beep.mp3", volume: 100 }
          #   end
          #
          def play_sound(filename, sink: nil, volume: nil)
            volume = PercentType.new(volume) unless volume.is_a?(PercentType) || volume.nil?
            java_send :playSound,
                      [java.lang.String, java.lang.String, PercentType.java_class],
                      sink,
                      filename.to_s,
                      volume
          end

          #
          # Play an audio stream from an URL to the given sink(s). Set url to nil if streaming should be stopped
          #
          # @param [String] url The URL of the audio stream
          # @param [String] sink The audio sink, or nil to use the default audio sink
          #
          # @return [void]
          #
          # @example Play an audio stream
          #   Audio.play_stream 'example.com'
          #
          def play_stream(url, sink: nil)
            playStream(sink&.to_s, url)
          end
        end
      end
    end
  end
end

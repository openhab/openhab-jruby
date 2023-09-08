# frozen_string_literal: true

module OpenHAB
  module Core
    module Actions
      # redefine these to do nothing so that rules won't fail

      module_function

      def notify(msg, email: nil)
        logger.debug("notify: #{msg}")
      end

      class Voice
        class << self
          def say(text, voice: nil, sink: nil, volume: nil)
            logger.debug("say: #{text}")
          end
        end
      end

      class Audio
        class << self
          def play_sound(filename, sink: nil, volume: nil)
            logger.debug("play_sound: #{filename}")
          end

          def play_stream(url, sink: nil)
            logger.debug("play_stream: #{url}")
          end
        end
      end
    end
  end
end

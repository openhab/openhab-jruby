# frozen_string_literal: true

module OpenHAB
  module Core
    module Actions
      # redefine these to do nothing so that rules won't fail

      class NotificationAction
        class << self
          def send_notification(
            email,
            msg,
            icon,
            severity,
            title = nil,
            on_click = nil,
            attachment = nil,
            button1 = nil,
            button2 = nil,
            button3 = nil
          )
            logger.debug("send_notification: #{email}, #{msg}, #{icon}, #{severity}, #{title}, #{on_click}, #{attachment}, #{button1}, #{button2}, #{button3}") # rubocop:disable Layout/LineLength
          end

          def send_broadcast_notification(
            msg,
            icon,
            severity,
            title = nil,
            on_click = nil,
            attachment = nil,
            button1 = nil,
            button2 = nil,
            button3 = nil
          )
            logger.debug("send_broadcast_notification: #{msg}, #{icon}, #{severity}, #{title}, #{on_click}, #{attachment}, #{button1}, #{button2}, #{button3}") # rubocop:disable Layout/LineLength
          end
        end
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

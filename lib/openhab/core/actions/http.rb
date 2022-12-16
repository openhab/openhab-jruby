# frozen_string_literal: true

module OpenHAB
  module Core
    module Actions
      # @see https://www.openhab.org/docs/configuration/actions.html#http-actions HTTP Actions
      class HTTP
        class << self
          #
          # Sends an HTTP GET request and returns the result as a String.
          #
          # @param [String] url
          # @param [Hash<String, String>] headers
          # @param [Duration, int, nil] timeout Timeout (in milliseconds, if given as an Integer)
          # @return [String] the response body
          # @return [nil] if an error occurred
          #
          def send_http_get_request(url, headers: {}, timeout: nil)
            timeout ||= 5_000
            timeout = timeout.to_millis if timeout.is_a?(Duration)

            sendHttpGetRequest(url, headers, timeout)
          end

          #
          # Sends an HTTP PUT request and returns the result as a String.
          #
          # @param [String] url
          # @param [String] content_type
          # @param [String] content
          # @param [Hash<String, String>] headers
          # @param [Duration, int, nil] timeout Timeout (in milliseconds, if given as an Integer)
          # @return [String] the response body
          # @return [nil] if an error occurred
          #
          def send_http_put_request(url, content_type = nil, content = nil, headers: {}, timeout: nil)
            timeout ||= 1_000
            timeout = timeout.to_millis if timeout.is_a?(Duration)

            sendHttpPutRequest(url, content_type, content, headers, timeout)
          end

          #
          # Sends an HTTP POST request and returns the result as a String.
          #
          # @param [String] url
          # @param [String] content_type
          # @param [String] content
          # @param [Hash<String, String>] headers
          # @param [Duration, int, nil] timeout Timeout (in milliseconds, if given as an Integer)
          # @return [String] the response body
          # @return [nil] if an error occurred
          #
          def send_http_post_request(url, content_type = nil, content = nil, headers: {}, timeout: nil)
            timeout ||= 1_000
            timeout = timeout.to_millis if timeout.is_a?(Duration)

            sendHttpPostRequest(url, content_type, content, headers, timeout)
          end

          #
          # Sends an HTTP DELETE request and returns the result as a String.
          #
          # @param [String] url
          # @param [Hash<String, String>] headers
          # @param [Duration, int, nil] timeout Timeout (in milliseconds, if given as an Integer)
          # @return [String] the response body
          # @return [nil] if an error occurred
          #
          def send_http_delete_request(url, headers: {}, timeout: nil)
            timeout ||= 1_000
            timeout = timeout.to_millis if timeout.is_a?(Duration)

            sendHttpDeleteRequest(url, headers, timeout)
          end
        end
      end
    end
  end
end

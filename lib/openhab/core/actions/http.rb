# frozen_string_literal: true

module OpenHAB
  module Core
    module Actions
      #
      # The HTTP actions allow you to send HTTP requests and receive the response.
      #
      # @example
      #   # Send a GET request
      #   headers = {
      #     "User-Agent": "JRuby/1.2.3", # enclose in quotes if the key contains dashes
      #     Accept: "application/json",
      #   }
      #   response = HTTP.get("http://example.com/list", headers: headers)
      #
      # @see https://www.openhab.org/docs/configuration/actions.html#http-actions HTTP Actions
      class HTTP
        class << self
          #
          # Sends an HTTP GET request and returns the result as a String.
          #
          # @param [String] url
          # @param [Hash<String, String>, Hash<Symbol, String>] headers
          #   A hash of headers to send with the request. Symbolic keys will be converted to strings.
          # @param [Duration, int, nil] timeout Timeout (in milliseconds, if given as an Integer)
          # @return [String] the response body
          # @return [nil] if an error occurred
          #
          def send_http_get_request(url, headers: {}, timeout: nil)
            timeout ||= 5_000
            timeout = timeout.to_millis if timeout.is_a?(Duration)

            sendHttpGetRequest(url, headers.transform_keys(&:to_s), timeout)
          end
          alias_method :get, :send_http_get_request

          #
          # Sends an HTTP PUT request and returns the result as a String.
          #
          # @param [String] url
          # @param [String] content_type
          # @param [String] content
          # @param [Hash<String, String>, Hash<Symbol, String>] headers
          #   A hash of headers to send with the request. Symbolic keys will be converted to strings.
          # @param [Duration, int, nil] timeout Timeout (in milliseconds, if given as an Integer)
          # @return [String] the response body
          # @return [nil] if an error occurred
          #
          def send_http_put_request(url, content_type = nil, content = nil, headers: {}, timeout: nil)
            timeout ||= 1_000
            timeout = timeout.to_millis if timeout.is_a?(Duration)

            sendHttpPutRequest(url, content_type, content, headers.transform_keys(&:to_s), timeout)
          end
          alias_method :put, :send_http_put_request

          #
          # Sends an HTTP POST request and returns the result as a String.
          #
          # @param [String] url
          # @param [String] content_type
          # @param [String] content
          # @param [Hash<String, String>, Hash<Symbol, String>] headers
          #   A hash of headers to send with the request. Symbolic keys will be converted to strings.
          # @param [Duration, int, nil] timeout Timeout (in milliseconds, if given as an Integer)
          # @return [String] the response body
          # @return [nil] if an error occurred
          #
          def send_http_post_request(url, content_type = nil, content = nil, headers: {}, timeout: nil)
            timeout ||= 1_000
            timeout = timeout.to_millis if timeout.is_a?(Duration)

            sendHttpPostRequest(url, content_type, content, headers.transform_keys(&:to_s), timeout)
          end
          alias_method :post, :send_http_post_request

          #
          # Sends an HTTP DELETE request and returns the result as a String.
          #
          # @param [String] url
          # @param [Hash<String, String>, Hash<Symbol, String>] headers
          #   A hash of headers to send with the request. Keys are strings or symbols, values are strings.
          #   Underscores in symbolic keys are replaced with dashes.
          # @param [Duration, int, nil] timeout Timeout (in milliseconds, if given as an Integer)
          # @return [String] the response body
          # @return [nil] if an error occurred
          #
          def send_http_delete_request(url, headers: {}, timeout: nil)
            timeout ||= 1_000
            timeout = timeout.to_millis if timeout.is_a?(Duration)

            sendHttpDeleteRequest(url, headers.transform_keys(&:to_s), timeout)
          end
          alias_method :delete, :send_http_delete_request
        end
      end
    end
  end
end

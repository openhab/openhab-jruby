# frozen_string_literal: true

require "pathname"
require "net/http"
require "marcel"

require_relative "generic_item"

module OpenHAB
  module Core
    module Items
      java_import org.openhab.core.library.items.ImageItem

      #
      # An {ImageItem} holds the binary image data as its state.
      #
      # @!attribute [r] state
      #   @return [RawType, nil]
      #
      # @!attribute [r] was
      #   @return [RawType, nil]
      #   @since openHAB 5.0
      #
      # @example Update from a base 64 encoded image string
      #   Image.update("data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABAQMAAAAl21bKAAAAA1BMVEUAAACnej3aAAAAAXRSTlMAQObYZgAAAApJREFUCNdjYAAAAAIAAeIhvDMAAAAASUVORK5CYII=")
      #
      # @example Update from image bytes and mime type
      #   Image.update_from_bytes(File.binread(File.join(Dir.tmpdir,'1x1.png')), mime_type: 'image/png')
      #
      # @example Update from URL
      #   Image.update_from_url('https://raw.githubusercontent.com/boc-tothefuture/openhab-jruby/main/features/assets/1x1.png')
      #
      # @example Update from File
      #   Image.update_from_file('/tmp/1x1.png')
      #
      # @example Log image data
      #   logger.info("Mime type: #{Image.state.mime_type}")
      #   logger.info("Number of bytes: #{Image.state.bytes.length}")
      #
      class ImageItem < GenericItem
        #
        # Update image from file
        #
        # @param [String] file location
        # @param [String] mime_type of image
        #
        def update_from_file(file, mime_type: nil)
          file_data = File.binread(file)
          mime_type ||= Marcel::MimeType.for(Pathname.new(file)) || Marcel::MimeType.for(file_data)
          update_from_bytes(file_data, mime_type:)
        end

        #
        # Update image from image at URL
        #
        # @param [String] uri location of image
        #
        def update_from_url(uri)
          logger.trace { "Downloading image from #{uri}" }
          response = Net::HTTP.get_response(URI(uri))
          mime_type = response["content-type"]
          bytes = response.body
          mime_type ||= detect_mime_from_bytes(bytes:)
          update_from_bytes(bytes, mime_type:)
        end

        #
        # Update image from image bytes
        #
        # @param [String] mime_type of image
        # @param [Object] bytes image data
        #
        def update_from_bytes(bytes, mime_type: nil)
          mime_type ||= detect_mime_from_bytes(bytes:)
          update(RawType.new(bytes.to_java_bytes, mime_type))
        end

        private

        #
        # Detect the mime type based on bytes
        #
        # @param [Array] bytes representing image data
        #
        # @return [String] mime type if it can be detected, nil otherwise
        #
        def detect_mime_from_bytes(bytes:)
          logger.trace("Detecting mime type from file image contents")
          Marcel::MimeType.for(bytes)
        end
      end
    end
  end
end

# @!parse ImageItem = OpenHAB::Core::Items::ImageItem

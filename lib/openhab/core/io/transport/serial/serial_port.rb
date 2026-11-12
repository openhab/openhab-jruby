# frozen_string_literal: true

require "stringio"

module OpenHAB
  module Core
    module IO
      module Transport
        module Serial
          # IO-like access to an openHAB serial port.
          #
          # @example
          #   OpenHAB::Core::IO::Transport::Serial::SerialPort.open("/dev/ttyUSB0",
          #                                                         baud: 9600,
          #                                                         data_bits: 8,
          #                                                         parity: :none,
          #                                                         stop_bits: 1) do |port|
          #     port.write("hello\r\n")
          #     port.read(1024) if port.wait_readable(1)
          #   end
          class SerialPort
            # @!visibility private
            PARITIES = { none: 0, odd: 1, even: 2, mark: 3, space: 4 }.freeze
            private_constant :PARITIES

            class << self
              # (see #initialize)
              # @!method open(name, baud: nil, data_bits: nil, parity: nil, stop_bits: nil, owner: "org.openhab.automation.jrubyscripting", timeout: 2000)
              #
              # Opens a port and ensures it is closed after an optional block.
              #
              # @yieldparam [SerialPort] port
              # @return [SerialPort, Object] The port if a block is not given, otherwise the result of the block.
              def open(...)
                port = new(...)
                return port unless block_given?

                begin
                  yield port
                ensure
                  port.close
                end
              end

              # define a finalizer without capturing the ruby object in the proc
              # @!visibility private
              def finalizer(java_serial_port)
                proc { java_serial_port.close }
              end
            end

            # @return [String] The port name.
            attr_reader :name

            private

            # @param [String] name Port name or provider URI.
            # @param [Integer, nil] baud Baud rate; nil preserves the provider default.
            # @param [5, 6, 7, 8, nil] data_bits
            # @param [:none, :odd, :even, :mark, :space, nil] parity
            # @param [1, 1.5, 2, nil] stop_bits
            # @param [String] owner Owner that should be reported by openHAB.
            # @param [Integer] timeout Port acquisition timeout in milliseconds.
            def initialize(name,
                           baud: nil,
                           data_bits: nil,
                           parity: nil,
                           stop_bits: nil,
                           owner: "org.openhab.automation.jrubyscripting",
                           timeout: 2000)
              identifier = Serial.manager.get_identifier(name)
              raise ArgumentError, "Invalid port name" unless identifier

              @port = identifier.open(owner, timeout)

              # Since the Java object often outlives the Ruby object, make
              # sure we clean up at the least when the Ruby ScriptEngine is
              # cleaned up. It's still preferable if the user explicitly
              # closes the port (or uses the block form of {#open}).
              ObjectSpace.define_finalizer(self, self.class.finalizer(@port))
              begin
                @name = @port.name
                @input = @port.input_stream
                @output = @port.output_stream
                raise IOError, "Serial port must support both reading and writing" unless @input && @output

                configure do
                  self.baud = baud if baud
                  self.data_bits = data_bits if data_bits
                  self.parity = parity if parity
                  self.stop_bits = stop_bits if stop_bits
                end
              rescue Exception
                close
                raise
              end
            end

            public

            # Writes strings as bytes and flushes them to the port.
            # @param [Object] string
            # @param [Array<Object>] strings
            # @return [Integer] Number of bytes written.
            def write(string, *strings)
              check_open
              bytes_written = [string, *strings].sum do |value|
                bytes = value.to_s.to_java_bytes
                @output.write(bytes, 0, bytes.length)
                bytes.length
              end
              @output.flush
              bytes_written
            rescue java.io.IOException => e
              raise IOError, e.message
            end

            # Writes objects followed by newlines, using Ruby IO formatting.
            # @param [Array<Object>] objects
            # @return [nil]
            def puts(*objects)
              formatted_write(:puts, *objects)
            end

            # Writes objects using Ruby IO formatting and output separators.
            # @param [Array<Object>] objects
            # @return [nil]
            def print(*objects)
              formatted_write(:print, *objects)
            end

            # Writes a formatted string.
            # @param [String] format
            # @param [Array<Object>] objects
            # @return [nil]
            def printf(format, *objects)
              formatted_write(:printf, format, *objects)
            end

            # Reads up to length bytes currently available, or nil if none are ready.
            # @param [Integer] length
            # @param [String, nil] outbuf
            # @return [String, nil]
            def read(length, outbuf = nil)
              result = read_nonblock(length, outbuf, exception: false)
              (result == :wait_readable) ? nil : result
            end

            # @param [Integer] length
            # @param [String, nil] outbuf
            # @param [Boolean] exception Raise IO::EAGAINWaitReadable if no bytes are ready, or EOFError at EOF.
            # @return [String, Symbol, nil]
            def read_nonblock(length, outbuf = nil, exception: true)
              check_open
              length = length.to_int
              raise ArgumentError, "negative length" if length.negative?

              return readpartial(0, outbuf) if length.zero?

              available = @input.available
              if available.zero?
                outbuf&.clear
                return :wait_readable unless exception

                raise ::IO::EAGAINWaitReadable, "read would block"
              end

              result = readpartial(0, outbuf)
              length = [length, available].min
              bytes = Java::byte[length].new
              count = @input.read(bytes, 0, length)
              return nil if count.negative? && !exception

              raise EOFError, "end of file reached" if count.negative?
              return result.replace(String.from_java_bytes(bytes).byteslice(0, count)) if count.positive?
              return :wait_readable unless exception

              raise ::IO::EAGAINWaitReadable, "read would block"
            rescue java.io.IOException => e
              raise IOError, e.message
            end

            # Blocks until at least one byte is available.
            # @param [Integer] length
            # @param [String, nil] outbuf
            # @return [String]
            def readpartial(length, outbuf = nil)
              check_open
              length = length.to_int
              raise ArgumentError, "negative length" if length.negative?

              result = outbuf.nil? ? +"".b : String.try_convert(outbuf)
              raise TypeError, "no implicit conversion of #{outbuf.class} into String" unless result

              result.replace("".b)
              return result if length.zero?

              bytes = Java::byte[length].new
              loop do
                count = @input.read(bytes, 0, length)
                raise EOFError, "end of file reached" if count.negative?
                return result.replace(String.from_java_bytes(bytes).byteslice(0, count)) if count.positive?

                # Serial receive timeouts can return zero without reaching EOF.
                check_open
                sleep 0.001
              end
            rescue java.io.IOException => e
              raise IOError, e.message
            end

            # @return [Integer, nil] The next available byte.
            def getbyte
              read(1)&.getbyte(0)
            end

            # Waits for input. A zero timeout only checks availability.
            # @param [Numeric, nil] timeout Seconds, or nil to wait indefinitely.
            # @return [self, nil]
            def wait_readable(timeout = nil)
              raise ArgumentError, "negative timeout" if timeout&.negative?

              deadline = monotonic_time + timeout if timeout
              loop do
                check_open
                return self if @input.available.positive?
                return nil if deadline && monotonic_time >= deadline

                sleep(deadline ? (deadline - monotonic_time).clamp(0, 0.01) : 0.01)
              end
            rescue java.io.IOException => e
              raise IOError, e.message
            end

            # @param [String] string
            # @return [self]
            def <<(string)
              write(string)
              self
            end

            # @return [self]
            def flush
              check_open
              @output.flush
              self
            rescue java.io.IOException => e
              raise IOError, e.message
            end

            # Releases the underlying serial port. Repeated calls are harmless.
            # @return [nil]
            def close
              return if closed?

              @closed = true
              @port.close
              ObjectSpace.undefine_finalizer(self)
              nil
            end

            # @return [Boolean]
            def closed?
              !!@closed
            end

            # Applies several settings at once. Failed blocks do not apply settings.
            #
            # @example
            #   port.configure do
            #     port.baud = 9600
            #     port.data_bits = 8
            #     port.parity = :none
            #     port.stop_bits = 1
            #   end
            #
            # @yieldparam [self] port
            # @return [self]
            def configure
              check_open
              previous = @configuration
              @configuration = if previous
                                 previous.dup
                               else
                                 [@port.baud_rate,
                                  @port.data_bits,
                                  @port.stop_bits,
                                  @port.parity]
                               end
              begin
                yield self
                @port.set_serial_port_params(*@configuration) unless previous
                previous&.replace(@configuration)
              ensure
                @configuration = previous
              end
              self
            end

            # @!attribute [rw] baud
            # @return [Integer]
            def baud
              check_open
              @configuration ? @configuration[0] : @port.baud_rate
            end

            def baud=(value)
              raise ArgumentError, "Invalid baud" unless value.is_a?(Integer) && value.positive?

              set_parameter(0, value)
            end

            # @!attribute [rw] data_bits
            # @return [5, 6, 7, 8]
            def data_bits
              check_open
              @configuration ? @configuration[1] : @port.data_bits
            end

            def data_bits=(value)
              raise ArgumentError, "Invalid data bits" unless [5, 6, 7, 8].include?(value)

              set_parameter(1, value)
            end

            # @!attribute [rw] stop_bits
            # @return [1, 1.5, 2]
            def stop_bits
              check_open
              value = @configuration ? @configuration[2] : @port.stop_bits
              (value == 3) ? 1.5 : value
            end

            def stop_bits=(value)
              raise ArgumentError, "Invalid stop bits" unless [1, 1.5, 2].include?(value)

              set_parameter(2, (value == 1.5) ? 3 : value.to_i) # rubocop:disable Lint/FloatComparison
            end

            # @!attribute [rw] parity
            # @return [:none, :odd, :even, :mark, :space]
            def parity
              check_open
              PARITIES.key(@configuration ? @configuration[3] : @port.parity)
            end

            def parity=(value)
              set_parameter(3, PARITIES.fetch(value) { raise ArgumentError, "Invalid parity" })
            end

            # @return [String]
            def inspect
              return "#<#{self.class.name}:#{name} (closed)>" if closed?

              "#<#{self.class.name}:#{name} #{baud} #{data_bits}#{parity.to_s[0].upcase}#{stop_bits}>"
            end

            private

            def set_parameter(index, value)
              check_open
              return configure { set_parameter(index, value) } unless @configuration

              @configuration[index] = value
            end

            def check_open
              raise IOError, "closed stream" if closed?
            end

            def formatted_write(method, *objects)
              check_open
              buffer = StringIO.new(+"".b)
              buffer.public_send(method, *objects)
              write(buffer.string)
              nil
            end

            def monotonic_time
              Process.clock_gettime(Process::CLOCK_MONOTONIC)
            end
          end
        end
      end
    end
  end
end

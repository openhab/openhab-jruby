# frozen_string_literal: true

require "openhab/console"
require "stringio"

module OpenHAB
  # @!visibility private
  module Console
    class Stdio
      attr_reader :internal_encoding

      def initialize(terminal)
        @terminal = terminal
        @external_encoding = Encoding.find(@terminal.encoding.name)
      end

      def set_encoding(_external, internal = nil, _options = {})
        @internal_encoding = internal
      end

      def tty?
        true
      end

      def winsize
        [@terminal.height, @terminal.width]
      end

      def inspect
        "#<#{self.class}>"
      end
    end

    class Stdin < Stdio
      attr_reader :external_encoding, :internal_encoding

      def initialize(terminal)
        super

        @byte_stream = terminal.input
        @buffer = StringIO.new.set_encoding(external_encoding)
      end

      def getbyte
        unless @buffer.eof?
          b = @buffer.getbyte
          @buffer.truncate(0) if @buffer.eof?
          return b
        end

        b = @byte_stream.read
        return nil if b.negative?

        b
      end

      def getc
        unless @buffer.eof?
          c = @buffer.getc
          @buffer.truncate(0) if @buffer.eof?
          return c
        end
        bytes = (+"").force_encoding(Encoding::BINARY)
        loop do
          b = getbyte
          return nil if b.nil?

          bytes << b.chr
          c = bytes.encode(external_encoding,
                           internal_encoding || Encoding.default_internal,
                           invalid: :replace,
                           undef: :replace,
                           replace: "")
          return c unless c.empty?
        end
      rescue java.io.InterruptedIOException
        raise Interrupt
      end

      def ungetbyte(byte)
        @buffer.ungetbyte(byte)
      end

      def ungetc(char)
        @buffer.ungetc(char)
      end

      def gets
        result = +""
        loop do
          c = getc
          if c.nil?
            return nil if result.empty?

            break
          end

          if c == "\x04" && result.empty? # ^D
            return nil
          elsif c == "\x7f"
            result.slice(0...-1)
          else
            result << c
          end
          break if c == "\n"
        end
        result
      rescue java.io.InterruptedIOException
        raise Interrupt
      end

      def read(bytes)
        r = readpartial(bytes)
        r.concat(readpartial(bytes - r.bytesize)) while r.bytesize < bytes
        r
      end

      def readpartial(bytes)
        available = @buffer.size - @buffer.tell
        if available.positive?
          bytes = available if available < bytes
          r = @buffer.read(bytes)
          @buffer.truncate(0) if @buffer.eof?
          return r
        end

        buffer = Java::byte[bytes].new
        read = @byte_stream.read_buffered(buffer)
        buffer = buffer[0..read] if read != bytes
        String.from_java_bytes(buffer)
      end
      alias_method :read_nonblock, :readpartial

      def wait_readable(timeout = nil)
        return true if (@buffer.size - @buffer.tell).positive?

        timeout = timeout ? 0 : timeout * 1000
        char = @byte_stream.read(timeout)
        return nil if char.negative? # timeout

        ungetc(char.chr(external_encoding))
        self
      end

      def raw(*)
        previous_attributes = @terminal.enter_raw_mode
        yield self
      ensure
        @terminal.set_attributes(previous_attributes)
      end
    end

    class Stdout < Stdio
      def initialize(terminal)
        super
        @writer = terminal.writer
      end

      def write(output)
        @writer.print(output)
        @writer.flush
      end
      alias_method :<<, :write

      def flush
        @writer.flush
      end

      def puts(output)
        output = output.join("\n") if output.is_a?(Array)
        @writer.println(output.to_s)
      end
    end
  end
end

$stdin = OpenHAB::Console::Stdin.new($terminal)
$stdout = $stderr = OpenHAB::Console::Stdout.new($terminal)

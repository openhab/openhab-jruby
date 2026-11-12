# frozen_string_literal: true

# The serial bundle is optional and its Java interfaces may not be installed.
RSpec.describe OpenHAB::Core::IO::Transport::Serial do
  subject(:port) do
    described_class::SerialPort.new("test")
  end

  let(:input) { java.io.ByteArrayInputStream.new("\x00\xFFhello".b.to_java_bytes) }
  let(:output) { java.io.ByteArrayOutputStream.new }
  let(:native_port) do
    # rubocop:disable-next RSpec/VerifiedDoubles -- ruby method names don't match Java method names
    double("org.openhab.core.io.transport.serial.SerialPort",
           name: "test",
           input_stream: input,
           output_stream: output,
           baud_rate: 9600,
           data_bits: 8,
           stop_bits: 1,
           parity: 0,
           close: nil,
           set_serial_port_params: nil)
  end
  let(:identifier) do
    # rubocop:disable-next RSpec/VerifiedDoubles -- ruby method names don't match Java method names
    double("org.openhab.core.io.transport.serial.SerialPortIdentifier",
           name: "test",
           open: native_port,
           currently_owned?: true,
           current_owner: "owner")
  end

  let(:stream) do
    # rubocop:disable-next RSpec/VerifiedDoubles -- ruby method names don't match Java method names
    stream = double("java.util.stream.Stream")
    allow(stream).to receive(:for_each).and_yield(identifier)
    stream
  end

  let(:manager) do
    org.openhab.core.io.transport.serial.internal.SerialPortManagerImpl.new(nil).tap do |manager|
      allow(manager).to receive_messages(get_identifier: identifier, identifiers: stream)
    end
  end

  it "flattens identifier ownership" do
    expect(manager.owned?("test")).to be true
    expect(manager.current_owner("test")).to eq("owner")
  end

  it "reports unavailable services and unknown ports" do
    allow(manager).to receive(:get_identifier).and_return(nil)
    expect(manager.current_owner("missing")).to be_nil
    expect(manager).not_to be_owned("missing")
  end

  it "enumerates names and closes the identifier stream" do
    expect(stream).to receive(:close)
    expect(manager.names).to eq(["test"])
  end

  it "closes discovery streams when enumeration raises" do
    expect(stream).to receive(:close)
    # rubocop:disable-next Lint/UnreachableLoop -- deliberately interrupt enumeration
    expect { manager.each { raise "failed" } }.to raise_error("failed")
  end

  context "with the fake manager" do
    let(:manager) do
      # rubocop:disable-next RSpec/VerifiedDoubles -- ruby method names don't match Java method names
      double("org.openhab.core.io.transport.serial.SerialPortManager", get_identifier: identifier)
    end

    before do
      allow(OpenHAB::Core::IO::Transport::Serial).to receive(:manager).and_return(manager)
    end

    it "reports the port's name" do
      described_class::SerialPort.open("test") do |opened|
        expect(opened.name).to eq("test")
      end
    end

    it "reads available binary data and reuses the supplied buffer" do
      buffer = +"old"
      expect(port.read(2, buffer)).to equal(buffer)
      expect(buffer.bytes).to eq([0, 255])
      expect(buffer.encoding).to eq(Encoding::BINARY)
      expect(port.read(100)).to eq("hello")
      expect(port.read(1)).to be_nil
      expect(port.getbyte).to be_nil
      expect(port.read(0)).to eq("")
      expect { port.read(-1) }.to raise_error(ArgumentError)
    end

    it "supports nonblocking reads and readiness checks" do
      expect(port.wait_readable(0)).to equal(port)
      port.read(100)
      expect(port.wait_readable(0.01)).to be_nil
      expect(port.read_nonblock(1, exception: false)).to eq(:wait_readable)
      expect { port.read_nonblock(1) }.to raise_error(IO::WaitReadable)
    end

    it "reports a zero-byte nonblocking read without retrying" do
      buffer = +"old"
      expect(input).to receive(:read).with(anything, 0, 1).once.and_return(0)

      expect(port.read_nonblock(1, buffer, exception: false)).to eq(:wait_readable)
      expect(buffer).to eq("")
    end

    it "raises wait readable for a zero-byte nonblocking read without retrying" do
      buffer = +"old"
      expect(input).to receive(:read).with(anything, 0, 1).once.and_return(0)

      expect { port.read_nonblock(1, buffer) }.to raise_error(IO::EAGAINWaitReadable)
      expect(buffer).to eq("")
    end

    it "returns nil from read and getbyte when available input yields zero bytes" do
      expect(input).to receive(:read).with(anything, 0, 1).twice.and_return(0)

      expect(port.read(1)).to be_nil
      expect(port.getbyte).to be_nil
    end

    it "reports EOF when available input reaches the end of the stream" do
      expect(input).to receive(:read).with(anything, 0, 1).once.and_return(-1)

      expect { port.read_nonblock(1) }.to raise_error(EOFError)
    end

    it "returns nil at EOF in non-raising reads and clears the supplied buffer" do
      buffer = +"old"
      expect(input).to receive(:read).with(anything, 0, 1).exactly(3).times.and_return(-1)

      expect(port.read_nonblock(1, buffer, exception: false)).to be_nil
      expect(buffer).to eq("")
      expect(port.read(1)).to be_nil
      expect(port.getbyte).to be_nil
    end

    it "writes binary data and supports IO output helpers" do
      expect(port.write("\xFF".b)).to eq(1)
      expect(port << "hi").to equal(port)
      port.puts("there")
      expect(port.flush).to equal(port)
      expect(String.from_java_bytes(output.to_byte_array)).to eq("\xFFhithere\n".b)
    end

    it "uses Java streams without converting them to Ruby IO" do
      expect(input).not_to receive(:to_io)
      expect(output).not_to receive(:to_io)
      expect(port.read(2).bytes).to eq([0, 255])
      expect(port.write("hello")).to eq(5)
      expect(port.flush).to equal(port)
    end

    it "preserves Ruby formatting for output helpers" do
      expect(port.puts(["one", ["two\n", nil]])).to be_nil
      expect(port.print("three", 4)).to be_nil
      expect(port.printf(" %02x", 255)).to be_nil
      expect(String.from_java_bytes(output.to_byte_array)).to eq("one\ntwo\n\nthree4 ff")
    end

    it "writes multiple strings as binary bytes and returns their total length" do
      expect(port.write("é", "\xFF".b, 42)).to eq(5)
      expect(String.from_java_bytes(output.to_byte_array)).to eq("é".b + "\xFF42".b)
    end

    it "reuses the supplied buffer for partial reads and reports EOF" do
      buffer = +"old"
      expect(port.readpartial(100, buffer)).to equal(buffer)
      expect(buffer).to eq("\x00\xFFhello".b)
      expect { port.readpartial(1, buffer) }.to raise_error(EOFError)
      expect(buffer).to eq("")
      expect(port.readpartial(0, buffer)).to equal(buffer)
      expect { port.readpartial(-1) }.to raise_error(ArgumentError)
    end

    it "retries a zero-byte serial timeout without treating it as EOF" do
      reads = 0
      allow(input).to receive(:read).and_wrap_original do |original, *args|
        reads += 1
        (reads == 1) ? 0 : original.call(*args)
      end
      expect(port.readpartial(2).bytes).to eq([0, 255])
    end

    it "translates Java stream failures into IOErrors" do
      port
      allow(input).to receive(:read).and_raise(java.io.IOException.new("read failed"))
      allow(output).to receive(:write).and_raise(java.io.IOException.new("write failed"))
      expect { port.readpartial(1) }.to raise_error(IOError, "read failed")
      expect { port.write("x") }.to raise_error(IOError, "write failed")
      allow(output).to receive(:flush).and_raise(java.io.IOException.new("flush failed"))
      expect { port.flush }.to raise_error(IOError, "flush failed")
    end

    it "translates availability failures for nonblocking reads, including exception: false" do
      allow(input).to receive(:available).and_raise(java.io.IOException.new("availability failed"))

      expect { port.read_nonblock(1) }.to raise_error(IOError, "availability failed")
      expect { port.read_nonblock(1, exception: false) }.to raise_error(IOError, "availability failed")
      expect { port.read(1) }.to raise_error(IOError, "availability failed")
      expect { port.getbyte }.to raise_error(IOError, "availability failed")
    end

    it "translates availability failures while waiting for input" do
      allow(input).to receive(:available).and_raise(java.io.IOException.new("availability failed"))

      expect { port.wait_readable }.to raise_error(IOError, "availability failed")
      expect { port.wait_readable(0) }.to raise_error(IOError, "availability failed")
    end

    it "leaves stream cleanup to the owning serial port" do
      port
      expect(input).not_to receive(:close)
      expect(output).not_to receive(:close)
      expect(native_port).to receive(:close).once
      port.close
    end

    it "batches configuration and maps parity and fractional stop bits" do
      expect(native_port).to receive(:set_serial_port_params).with(19_200, 7, 3, 2).once
      port.configure do |serial|
        serial.baud = 19_200
        serial.data_bits = 7
        serial.stop_bits = 1.5
        serial.parity = :even
        expect([serial.baud, serial.data_bits, serial.stop_bits, serial.parity]).to eq([19_200, 7, 1.5, :even])
      end
    end

    it "does not apply configuration after a failed block" do
      port
      expect(native_port).not_to receive(:set_serial_port_params)
      expect do
        port.configure do
          port.baud = 19_200
          raise "failed"
        end
      end.to raise_error("failed")
      expect(port.baud).to eq(9600)
      expect { port.parity = :invalid }.to raise_error(ArgumentError)
      expect { port.data_bits = 9 }.to raise_error(ArgumentError)
    end

    it "supports blocking partial reads without corrupting subsequent reads" do
      expect(port.readpartial(2).bytes).to eq([0, 255])
      expect(port.getbyte).to eq("h".ord)
      expect(port.read(100)).to eq("ello")
    end

    it "supports nested configuration blocks" do
      port
      expect(native_port).to receive(:set_serial_port_params).with(19_200, 7, 1, 0).once
      port.configure do
        port.baud = 19_200
        port.configure { port.data_bits = 7 }
        expect(port.data_bits).to eq(7)
      end
    end

    it "applies an individual setting with the existing parameters" do
      port
      expect(native_port).to receive(:set_serial_port_params).with(9600, 8, 1, 1)
      port.parity = :odd
    end

    it "closes once and rejects subsequent IO" do
      port
      expect(native_port).to receive(:close).once
      2.times { port.close }
      expect(port).to be_closed
      expect { port.read(1) }.to raise_error(IOError, /closed/)
      expect { port.write("x") }.to raise_error(IOError, /closed/)
    end

    it "releases a port when initial configuration fails" do
      expect(native_port).to receive(:close)
      expect { described_class::SerialPort.new("test", parity: :invalid) }.to raise_error(ArgumentError)
    end

    it "closes after a block raises" do
      expect(native_port).to receive(:close)
      expect { described_class::SerialPort.open("test") { raise "failed" } }.to raise_error("failed")
    end
  end
end

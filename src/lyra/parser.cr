class Lyra::Parser
  enum State
    CommandStart
    ArgStart
  end

  class ParseException < Exception
  end

  getter command_size : Int32 = 0

  def initialize(@io : IO)
    @state = State::CommandStart
  end

  COMMAND_SIZE_MAX = 65_535

  # Returns the name of the parsed command, or nil if the connection was closed.
  def read_name : String?
    error "can't read command-name when positioned at command-arg" unless @state.command_start?

    name = @io.gets(' ', limit: 32 + 1, chomp: true)
    return nil unless name

    error "command-name is longer than 32 characters" if name.size > 32
    unless name.each_char.all? { |c| command_name_char? c }
      error "command-name #{name.inspect} does not contain only A-Z0-9"
    end

    @command_size = name.bytesize + 1
    @state = State::ArgStart

    name
  end

  private def command_name_char?(char)
    'A' <= char <= 'Z' || '0' <= char <= '9'
  end

  # Returns true if another argument can be read from this command.
  def has_arg?
    @state.arg_start?
  end

  # Reads an argument of the currently parsing command, as a string.
  def read_arg : String
    read_arg do |arg|
      String.build do |str|
        IO.copy(arg, str)
      end
    end
  end

  # Reads an argument of the currently parsing command, yielding the argument
  # data in an IO passed to the provided block.
  def read_arg(& : IO -> T) : T forall T
    error "can't read command-arg when positioned at command-name" unless @state.arg_start?

    # TODO: optimize

    io = IO::Memory.new

    byte = @io.read_byte
    raise IO::EOFError.new unless byte
    @command_size += 1

    case byte
    when ':'
      last_arg = true
      target_byte = '\n'.ord.to_u8
    when ' '
      # Zero-length argument

      error "command size was greater than #{COMMAND_SIZE_MAX} bytes" if @command_size > COMMAND_SIZE_MAX
      return yield io.rewind
    else
      io.write_byte(byte)

      last_arg = false
      target_byte = ' '.ord.to_u8
    end

    while @command_size < COMMAND_SIZE_MAX
      byte = @io.read_byte
      raise IO::EOFError.new unless byte
      @command_size += 1

      break if byte == target_byte

      io.write_byte(byte)
    end

    error "command size was greater than #{COMMAND_SIZE_MAX} bytes" unless byte == target_byte

    if last_arg
      # We read the newline so it's the start of a new command
      @state = State::CommandStart
    end

    yield io.rewind
  end

  private def error(string)
    raise ParseException.new(string)
  end
end

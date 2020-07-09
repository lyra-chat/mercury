class Lyra::Connection
  def initialize(@io : IO)
    @parser = Parser.new(io)
  end

  def send(command : Command)
    @io << command.name << ' '

    0.upto(command.args.size - 2) do |i|
      @io << command.args[i] << ' '
    end

    @io << ':' << command.args.last << '\n'
  end

  # See `Parser#command_size`.
  def command_size : Int32
    @parser.command_size
  end

  # See `Parser#read_name`.
  def read_name : String?
    @parser.read_name
  end

  # See `Parser#has_arg?`.
  def has_arg?
    @parser.has_arg?
  end

  # See `Parser#read_arg`.
  def read_arg : String
    @parser.read_arg
  end

  # See `Parser#read_arg`.
  def read_arg
    @parser.read_arg { |io| yield io }
  end
end

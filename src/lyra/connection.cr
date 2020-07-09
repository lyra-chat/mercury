require "./parser"

class Lyra::Connection
  getter parser : Parser

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
end

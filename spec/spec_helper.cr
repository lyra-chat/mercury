require "spec"
require "../src/mercury"

def expect_serializes(command : Lyra::Command, expected : String)
  io = IO::Memory.new
  connection = Lyra::Connection.new(io)
  connection.send(command)
  io.to_s.should eq(expected + "\n")
end

def parse(command : T.class, serialized : String) : T forall T
  io = IO::Memory.new(serialized + "\n")
  parser = Lyra::Parser.new(io)
  parser.read_name
  T.new(parser)
end

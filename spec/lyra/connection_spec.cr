require "../spec_helper"

describe Lyra::Connection do
  it "reads commands" do
    io = IO::Memory.new "HELLO 0.1.0 foo :{}\n"
    connection = Lyra::Connection.new(io)

    command = connection.read
    command.should be_a(Lyra::Command::Hello)

    connection.read.should be_nil
  end
end

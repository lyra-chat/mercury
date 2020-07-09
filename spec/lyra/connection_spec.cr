require "../spec_helper"

describe Lyra::Connection do
  it "acts as a parser" do
    io = IO::Memory.new <<-'EOF'
      FOO bar baz :arg with spaces
      BAZ :bar
      BING  :zero length arg

      EOF

    parser = Lyra::Connection.new(io)

    parser.read_name.should eq("FOO")
    parser.command_size.should eq(4)
    parser.read_arg.should eq("bar")
    parser.command_size.should eq(8)
    parser.read_arg.should eq("baz")
    parser.command_size.should eq(12)
    parser.read_arg.should eq("arg with spaces")
    parser.command_size.should eq(29)

    parser.read_name.should eq("BAZ")
    parser.command_size.should eq(4)
    parser.read_arg.should eq("bar")
    parser.command_size.should eq(9)

    parser.read_name.should eq("BING")
    parser.command_size.should eq(5)
    parser.read_arg.should eq("")
    parser.command_size.should eq(6)
    parser.read_arg.should eq("zero length arg")
    parser.command_size.should eq(23)

    parser.read_name.should be_nil
  end
end

require "../spec_helper"

private def new_parser(str : String)
  io = IO::Memory.new(str)
  Lyra::Parser.new(io)
end

describe Lyra::Parser do
  it "parses" do
    parser = new_parser <<-'EOF'
      FOO bar baz :arg with spaces
      BAZ :bar
      BING  :zero length arg

      EOF

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

  describe "#read_name" do
    it "doesn't read command-name when positioned at arg" do
      parser = new_parser <<-'EOF'
        CMD arg :arg
        CMD arg :arg

        EOF

      parser.read_name.should eq("CMD")
      expect_raises(Lyra::Parser::ParseException, "can't read command-name when positioned at command-arg") do
        parser.read_name
      end
      parser.read_arg.should eq("arg")
      expect_raises(Lyra::Parser::ParseException, "can't read command-name when positioned at command-arg") do
        parser.read_name
      end
      parser.read_arg.should eq("arg")
      parser.read_name.should eq("CMD")
      expect_raises(Lyra::Parser::ParseException, "can't read command-name when positioned at command-arg") do
        parser.read_name
      end
      parser.read_arg.should eq("arg")
      expect_raises(Lyra::Parser::ParseException, "can't read command-name when positioned at command-arg") do
        parser.read_name
      end
      parser.read_arg.should eq("arg")
      parser.read_name.should be_nil
    end

    it "doesn't parse too-long command-name" do
      parser = new_parser <<-EOF
        AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA :bar
        AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA :bar
        BAZ :bar

        EOF

      parser.read_name.should eq("A" * 32)
      parser.read_arg.should eq("bar")

      expect_raises(Lyra::Parser::ParseException, "command-name is longer than 32 characters") do
        parser.read_name.should eq("A" * 33)
      end
    end

    it "doesn't parse non-alphanumeric command-name" do
      parser = new_parser <<-EOF
        ABCDEFGHIJKLMNOPQRSTUVWXYZ :
        1234567890 :
        lowercase :

        EOF

      parser.read_name.should eq("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
      parser.read_arg.should eq("")

      parser.read_name.should eq("1234567890")
      parser.read_arg.should eq("")

      expect_raises(Lyra::Parser::ParseException, %(command-name "lowercase" does not contain only A-Z0-9)) do
        parser.read_name.should eq("")
      end
    end
  end

  describe "#read_arg" do
    it "reads IO" do
      parser = new_parser <<-'EOF'
        FOO :bar
        BAZ :bar

        EOF

      parser.read_name.should eq("FOO")
      parser.read_arg do |io|
        io.read_char.should eq('b')
        io.read_char.should eq('a')
        io.read_char.should eq('r')
        io.read_char.should eq(nil)
      end
      parser.read_name.should eq("BAZ")
      parser.read_arg do |io|
        io.read_char.should eq('b')
        io.read_char.should eq('a')
        io.read_char.should eq('r')
        io.read_char.should eq(nil)
      end
      parser.read_name.should be_nil
    end

    it "doesn't read command-arg when positioned at name" do
      parser = new_parser <<-'EOF'
        CMD arg :arg
        CMD arg :arg

        EOF

      parser.read_name.should eq("CMD")
      expect_raises(Lyra::Parser::ParseException, "can't read command-name when positioned at command-arg") do
        parser.read_name
      end
      parser.read_arg.should eq("arg")
      expect_raises(Lyra::Parser::ParseException, "can't read command-name when positioned at command-arg") do
        parser.read_name
      end
      parser.read_arg.should eq("arg")
      parser.read_name.should eq("CMD")
      expect_raises(Lyra::Parser::ParseException, "can't read command-name when positioned at command-arg") do
        parser.read_name
      end
      parser.read_arg.should eq("arg")
      expect_raises(Lyra::Parser::ParseException, "can't read command-name when positioned at command-arg") do
        parser.read_name
      end
      parser.read_arg.should eq("arg")
      parser.read_name.should be_nil
    end

    it "raises on unexpected EOF" do
      {"CMD", "CMD ", "CMD \n", "CMD :"}.each do |test|
        parser = new_parser "CMD "
        parser.read_name.should eq("CMD")
        expect_raises(IO::EOFError) do
          parser.read_arg
        end
      end
    end

    it "raises on too-large command (non-end)" do
      str = "CMD arg1 arg2 #{"a" * (65535 - 15)} "
      str.bytesize.should eq(65535)
      parser = new_parser(str)
      parser.read_name.should eq("CMD")
      parser.read_arg.should eq("arg1")
      parser.read_arg.should eq("arg2")
      parser.command_size.should eq(14)
      parser.read_arg.should eq("a" * (65535 - 15))

      str = "CMD arg1 arg2 #{"a" * (65535 - 14)} "
      str.bytesize.should eq(65536)
      parser = new_parser(str)
      parser.read_name.should eq("CMD")
      parser.read_arg.should eq("arg1")
      parser.read_arg.should eq("arg2")
      expect_raises(Lyra::Parser::ParseException, "command size was greater than 65535 bytes") do
        parser.read_arg
      end
    end

    it "raises on too-large command (end)" do
      str = "CMD arg1 arg2 :#{"a" * (65535 - 16)}\n"
      str.bytesize.should eq(65535)
      parser = new_parser(str)
      parser.read_name.should eq("CMD")
      parser.read_arg.should eq("arg1")
      parser.read_arg.should eq("arg2")
      parser.command_size.should eq(14)
      parser.read_arg.should eq("a" * (65535 - 16))

      str = "CMD arg1 arg2 :#{"a" * (65535 - 15)}\n"
      str.bytesize.should eq(65536)
      parser = new_parser(str)
      parser.read_name.should eq("CMD")
      parser.read_arg.should eq("arg1")
      parser.read_arg.should eq("arg2")
      expect_raises(Lyra::Parser::ParseException, "command size was greater than 65535 bytes") do
        parser.read_arg
      end
    end
  end
end

require "../../spec_helper"

describe Lyra::Command::Hello do
  describe "serialization" do
    it "serializes" do
      hello = Lyra::Command::Hello.new
      hello.extensions << "foo"

      expect_serializes(hello, "HELLO 0.1.0 foo :{}")
    end

    it "handles no extensions" do
      hello = Lyra::Command::Hello.new

      expect_serializes(hello, "HELLO 0.1.0  :{}")
    end
  end

  describe "deserialization" do
    it "parses" do
      command = parse(Lyra::Command::Hello, "HELLO 4.2.0 foo :{}")
      command.protocol_version.should eq("4.2.0")
      command.extensions.should eq(["foo"])
    end

    it "handles no extensions" do
      command = parse(Lyra::Command::Hello, "HELLO 4.2.0  :{}")
      command.protocol_version.should eq("4.2.0")
      command.extensions.should eq([] of String)
    end

    it "errors on empty extensions" do
      expect_raises(Lyra::Command::ParseException, "empty protocol extension provided") do
        parse(Lyra::Command::Hello, "HELLO 4.2.0 foo, :{}")
      end

      expect_raises(Lyra::Command::ParseException, "empty protocol extension provided") do
        parse(Lyra::Command::Hello, "HELLO 4.2.0 ,foo :{}")
      end

      expect_raises(Lyra::Command::ParseException, "empty protocol extension provided") do
        parse(Lyra::Command::Hello, "HELLO 4.2.0 , :{}")
      end
    end
  end
end

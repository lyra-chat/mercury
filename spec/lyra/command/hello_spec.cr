require "../../spec_helper"

describe Lyra::Command::Hello do
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

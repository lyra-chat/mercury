require "../command"

class Lyra::Command::Hello < Lyra::Command
  def name : String
    "HELLO"
  end

  getter protocol_version : String
  getter extensions = Array(String).new
  getter metadata = Metadata.new

  def initialize(@protocol_version = "0.1.0")
  end

  def initialize(parser : Lyra::Parser)
    @protocol_version = parser.read_arg
    @extensions = parser.read_arg.split(',')

    @extensions.clear if @extensions == [""] # This is the case of no extensions
    parse_error("empty protocol extension provided") if @extensions.any? { |e| e.empty? }

    @metadata = parser.read_arg { |io| Metadata.from_json(io) }
  end

  class Metadata
    include JSON::Serializable

    def initialize
    end

    def to_s(io)
      to_json(io)
    end
  end

  def args : Indexable
    {protocol_version, extensions.join(','), metadata}
  end
end

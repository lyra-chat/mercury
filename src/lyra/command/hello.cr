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

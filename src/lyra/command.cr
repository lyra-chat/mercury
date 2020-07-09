require "json"

abstract class Lyra::Command
  abstract def name : String
  abstract def args : Indexable

  class ParseException < Exception
  end

  private def parse_error(string)
    raise ParseException.new(string)
  end
end

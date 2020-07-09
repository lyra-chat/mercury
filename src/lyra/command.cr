require "json"

abstract class Lyra::Command
  abstract def name : String
  abstract def args : Indexable

  class ParseException < Exception
  end

  private def parse_error(string)
    raise ParseException.new(string)
  end

  class_getter commands = Hash(String, Lyra::Command.class).new

  def self.register(command, clazz) : Nil
    commands[command] = clazz
  end
end

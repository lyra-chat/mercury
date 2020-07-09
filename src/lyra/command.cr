require "json"

abstract class Lyra::Command
  abstract def name : String
  abstract def args : Indexable
end

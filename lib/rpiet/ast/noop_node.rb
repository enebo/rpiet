require_relative 'node'

module RPiet
  ##
  # Entry point into the program.  Not strictly neccesary
  # but we will kill this during analysis
  class NoopNode < Node
    def execute(_); end  # No-op
  end
end
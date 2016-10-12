require_relative 'node'

module RPiet
  ##
  # Roll the stack
  class RollNode < Node
    def execute(machine)
      stack = machine.stack
      depth, num = stack.pop(2)
      num %= depth
      return if depth <= 0 || num == 0
      if num > 0
        stack[-depth..-1] = stack[-num..-1] + stack[-depth...-num]
      elsif num < 0
        stack[-depth..-1] = stack[-depth...-num] + stack[-num..-1]
      end
    end
  end
end
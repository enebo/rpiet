module RPiet
  module ASG
    ##
    # Base class of all nodes
    class Node
      attr_accessor :next_node
      attr_reader :step, :x, :y

      def initialize(step, x, y, *)
        @step, @x, @y = step, x, y
      end

      def visit(visitor)
        visitor.visit self
      end

      # Does this node represent a branching operation?
      def branch? = false

      ##
      # Is this node hidden from the perspective of calling next_step?
      # In simpler interpreter noop, cc, and dp will change during next_step
      # while in graph and ir interpreters they are explicit actions.
      def hidden? = false

      # What possible paths can this node navigate to next
      def paths = [@next_node]

      def add_path(node, *)
        @next_node = node
      end

      def operation = self.class.operation_name.to_sym

      def self.operation_name = name.sub(/.*::/, '').sub('Node', '').downcase

      def exec(machine)
        #      puts "exec p##{@step} [#{@x}, #{@y}](#{self.class.operation_name}): #{machine}"
        value = execute(machine)
        return value if branch?
        next_node
      end

      def inspect
        "p##{@step} [#{@x}, #{@y}](#{operation})"
      end
      alias :to_s :inspect

      def self.create(step, x, y, operation, *extra_args)
        Nodes[operation].new step, x, y, *extra_args
      end
    end

    ##
    # Perform common mathematical binary operation
    class MathNode < Node
      def initialize(step, x, y, operation, *)
        super(step, x, y)
        @operation = operation
      end

      def execute(machine)
        stack = machine.stack
        return nil unless stack.length >= 2
        a, b = stack.pop(2)
        stack << a.send(@operation, b)
      end
    end

    ##
    # Add two values from stack
    class AddNode < MathNode
      def initialize(step, x, y, *) = super(step, x, y, :+)
    end

    ##
    # When dp changes due to natural navigation we update it
    # to the new value
    class CcNode < Node
      attr_reader :value

      def initialize(step, x, y, cc_ordinal, *)
        super(step, x, y)
        @value = cc_ordinal
      end

      def hidden? = true

      def execute(machine) = machine.cc.from_ordinal!(@value)
    end

    ##
    # Read in character from the console and push on the stack
    class CinNode < Node
      def execute(machine)
        $stdout.write "> "
        machine.stack << $stdin.read(1).ord
      end
    end

    ##
    # Display top element of the stack to the console as a character.
    class CoutNode < Node
      def execute(machine) = print machine.stack.pop.chr
    end

    ##
    # Add two values from stack
    class DivNode < MathNode
      def initialize(step, x, y, *)= super(step, x, y, :/)
    end

    ##
    # When dp changes due to natural navigation we update it
    # to the new value
    class DpNode < Node
      attr_reader :value

      def initialize(step, x, y, _, dp_ordinal)
        super(step, x, y)
        @value = dp_ordinal
      end

      def hidden? = true

      def execute(machine) = machine.dp.from_ordinal!(@value)
    end

    ##
    # Duplicate top element of the stack.
    class DupNode < Node
      def execute(machine)
        stack = machine.stack
        stack << stack[-1] if stack[-1]
      end
    end

    ##
    # Greater than operation on top two stack values
    class GtrNode < Node
      def execute(machine)
        stack = machine.stack
        return nil unless stack.length >= 2
        a, b = stack.pop(2)
        stack << (a > b ? 1 : 0)
      end
    end

    ##
    # Modulos two values from stack
    class ModNode < MathNode
      def initialize(step, x, y, *) = super(step, x, y, :%)
    end

    ##
    # Multiply two values from stack
    class MultNode < MathNode
      def initialize(step, x, y, *)= super(step, x, y, :*)
    end

    ##
    # Read in number from the console and push on the stack
    class NinNode < Node
      def execute(machine)
        puts "Enter an integer: "
        machine.stack << $stdin.gets.to_i
      end
    end

    ##
    # Entry point into the program.  Not strictly necessary
    # but we will kill this during analysis
    class NoopNode < Node
      def hidden? = true

      def execute(_); end  # No-op
    end

    ##
    # Greater than operation on top two stack values
    class NotNode < Node
      def execute(machine)
        stack = machine.stack
        top = stack.pop
        stack << (!top || top == 0 ? 1 : 0)
      end
    end

    ##
    # Diplay top element of the stack to the console.
    class NoutNode < Node
      def execute(machine) = print machine.stack.pop
    end

    ##
    # Rotate the direction based on top stack value and
    # change execution flow.
    class PntrNode < Node
      def branch? = true

      def add_path(node, _, dp_value)
        @values ||= []
        @values[dp_value] = node
      end

      # What possible paths can this node navigate to next
      def paths = @values

      def execute(machine)
        top = machine.stack.pop
        @values[machine.dp.rotate!(top).value]
      end
    end

    ##
    # Pop a value from the stack
    class PopNode < Node
      def execute(machine) = machine.stack.pop
    end

    ##
    # Push a value onto the stack
    class PushNode < Node
      attr_reader :value

      def initialize(step, x, y, value)
        super(step, x, y)
        @value = value
      end

      def execute(machine) = machine.stack << @value
    end

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

    ##
    # Subtract two values from stack
    class SubNode < MathNode
      def initialize(step, x, y, *)= super(step, x, y, :-)
    end

    ##
    # Rotate the codel chooser based on top stack value and
    # change execution flow.
    class SwchNode < Node
      def branch? = true

      def add_path(node, cc, _)
        if cc == RPiet::CodelChooser::LEFT
          @left = node
        else
          @right = node
        end
      end

      # What possible paths can this node navigate to next
      def paths = [@left, @right]

      def execute(machine)
        top = machine.stack.pop
        if machine.cc.switch!(top) == RPiet::CodelChooser::LEFT
          @left
        else
          @right
        end
      end
    end

    Nodes = {
      noop: NoopNode,
      push: PushNode,
      pop: PopNode,
      add: AddNode,
      sub: SubNode,
      mult: MultNode,
      div: DivNode,
      mod: ModNode,
      not: NotNode,
      gtr: GtrNode,
      pntr: PntrNode,
      swch: SwchNode,
      dup: DupNode,
      roll: RollNode,
      nin: NinNode,
      cin: CinNode,
      nout: NoutNode,
      cout: CoutNode,
      dp: DpNode,
      cc: CcNode
    }
  end
end
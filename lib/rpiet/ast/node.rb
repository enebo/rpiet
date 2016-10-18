module RPiet
  ##
  # Base class of all nodes
  class Node
    attr_reader :next_node

    def initialize(step, x, y)
      @step, @x, @y = step, x, y
    end

    def visit(visitor)
      visitor.visit self
    end

    # Does this node represent a branching operation?
    def branch?
      false
    end

    # What possible paths can this node navigate to next
    def paths
      [@next_node]
    end

    def add_path(node, *)
      @next_node = node
    end

    def operation
      self.class.operation_name.to_sym
    end

    def self.operation_name
      name.sub(/.*::/, '').sub('Node', '').downcase
    end

    def exec(machine)
      puts "exec p##{@step} [#{@x}, #{@y}](#{self.class.operation_name}): #{machine}"
      value = execute(machine)
      return value if branch?
      next_node
    end

    def inspect
      "p##{@step} [#{@x}, #{@y}](#{operation})"
    end
    alias :to_s :inspect

    def self.create(step, x, y, operation, *extra_args)
      klazz = Nodes[Operations.find_index(operation)]
      if operation == :push || operation == :dp || operation == :cc
        klazz.new step, x, y, *extra_args
      else
        klazz.new step, x, y
      end
    end

    Operations = [:noop, :push, :pop, :add,  :sub, :mult, :div,  :mod, :not,
                  :gtr,  :pntr, :swch, :dup,  :roll, :nin, :cin, :nout, :cout,
                  :dp, :cc]

    Nodes = []
    Operations.each do |operation|
      require_relative "#{operation}_node"
      Nodes << RPiet.const_get("#{operation.to_s.capitalize}Node")
    end
  end
end
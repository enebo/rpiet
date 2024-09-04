require_relative 'optimizer'

module RPiet
  ##
  # Base class of all nodes
  class Node
    include Optimizer

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

    Nodes = {}
    [:noop, :push, :pop, :add,  :sub, :mult, :div,  :mod, :not,
     :gtr,  :pntr, :swch, :dup,  :roll, :nin, :cin, :nout, :cout,
     :dp, :cc].each do |operation|
      require_relative "#{operation}_node"
      Nodes[operation] = RPiet.const_get("#{operation.to_s.capitalize}Node")
    end
  end
end

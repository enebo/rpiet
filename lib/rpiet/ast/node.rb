module RPiet
  ##
  # Base class of all nodes
  class Node
    Operations = [:noop, :push, :pop, :add,  :sub, :mult, :div,  :mod, :not,
                  :gtr,  :pntr, :swch, :dup,  :roll, :nin, :cin, :nout, :cout,
                  :dp, :cc]

    Nodes = []
    Operations.each do |operation|
      require_relative "#{operation}_node"
      Nodes << RPiet.const_get("#{operation.to_s.capitalize}Node")
    end

    attr_reader :next_node

    def initialize(step, x, y)
      @step, @x, @y = step, x, y
    end

    def branch?
      false
    end

    def add_path(node, *)
      @next_node = node
    end

    def name
      self.class.name.sub('_node', '').downcase
    end

    def exec(machine)
      #puts "exec p##{@step} [#{@x}, #{@y}](#{name}): #{machine}"
      value = execute(machine)
      return value if branch?
      next_node
    end

    def inspect
      "p##{@step} [#{@x}, #{@y}](#{name})"
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
  end
end
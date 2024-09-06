require_relative '../asg/visitor'
require_relative 'instructions'
require_relative 'operands'

module RPiet
  # Visit each node from ASG and translate into simpler more
  # traditional instructions.  These instructions will be
  # translated into different back-ends.
  class Builder < Visitor
    DEBUG = false
    include RPiet::IR::Instructions, RPiet::IR::Operands

    attr_reader :instructions, :dp, :cc

    def initialize
      super
      @instructions, @variables = [], []
      @node_mappings = {} # instruction -> node
      @jump_labels = {} # node -> label
      @variable_counter = 0
      @dp, @cc = VariableOperand.new('%dp'), VariableOperand.new('%cc')
      @current_node = nil
      add CopyInstr.new(@dp, num(0))
      add CopyInstr.new(@cc, num(-1))
    end

    def visit_first(node)
      add NodeInstr.new(node.operation, node.step, node.x, node.y) if DEBUG
      @current_node = node
      instructions_for node
      super node
    end

    def visit_first_pntr(node, worklist)
      NodeInstr.new(node.operation, node.step, node.x, node.y) if DEBUG

      # In stack make pntr = (pntr + 1) % 4
      @current_node = node
      variables(1) do |pop|
        add PopInstr.new pop
        add AddInstr.new @dp, @dp, pop
      end
      add ModInstr.new @dp, @dp, num(4)
      end_label = LabelInstr.new('end_pntr')
      4.times do |i|
        next_label = i == 3 ? end_label : LabelInstr.new("pntr[#{i}]")
        add BNEInstr.new @dp, num(i), next_label
        worklist << node.paths[i]
        visit(worklist)
        add next_label unless i == 3
      end
      add end_label

      nil
    end

    def visit_first_swch(node, worklist)
      add NodeInstr.new(node.operation, node.step, node.x, node.y) if DEBUG

      @current_node = node
      variables(2) do |pop, result|
        else_label, end_label = LabelInstr.new('false'), LabelInstr.new('end_swch_if')
        add PopInstr.new pop
        add ModInstr.new pop, pop, num(2)
        add PowInstr.new pop, num(-1), pop
        add MultInstr.new @cc, @cc, pop
      end
      next_label = LabelInstr.new "swch[-1]"
      add BNEInstr.new @cc, num(-1), next_label
      worklist << node.paths[0]
      visit(worklist)
      add next_label
      worklist << node.paths[1]
      visit(worklist)
      
      nil
    end

    def visit_again(node)
      add NodeInstr.new("re-#{node.operation}", node.step, node.x, node.y) if DEBUG
      
      label = @jump_labels[node]

      unless label  # first time to insert label
        label = LabelInstr.new(node.object_id)
        @jump_labels[node] = label
        index = @instructions.find_index(@node_mappings[node])
        @instructions.insert index, label
      end

      # This will be in proper place because all new nodes are added to
      # end of instruction list.
      add JumpInstr.new label
    end

    def add(instruction)
      # For first instruction that represents a node from ASG we record it
      # so when we encounter a cycle we know where we should jump.
      if @current_node
        @node_mappings[@current_node] = instruction
        @current_node = nil
      end

      @instructions << instruction
    end

    def num(value)
      NumOperand.new(value)
    end

    def string(value)
      StringOperand.new(value)
    end

    def variables(count)
      variables = Array.new(count) { |_| acquire_variable }
      yield *variables
    ensure
      variables.each { |variable| return_variable variable }
    end

    def acquire_variable
      @variables.pop || VariableOperand.new("%v_#{@variable_counter += 1}")
    end

    def return_variable(variable)
      @variables.push variable
    end

    def push(operand)
      PushInstr.new operand
    end

    def instructions_for(node)
      case node.operation
        when :noop then add NoopInstr.new
        when :push then add push(num(node.value))
        when :pop then variables(1) { |variable| add PopInstr.new variable }
        when :add then bin_op AddInstr
        when :sub then bin_op SubInstr
        when :mult then bin_op MultInstr
        when :div then bin_op DivInstr
        when :mod then bin_op ModInstr
        when :nout then unary_op NoutInstr, result: false
        when :cout then unary_op CoutInstr, result: false
        when :gtr then
          variables(2) do |variable1, variable2|
            add PopInstr.new variable2
            add PopInstr.new variable1
            true_label, end_label = LabelInstr.new('true'), LabelInstr.new('end')
            add GTInstr.new variable1, variable2, true_label
            add push(num(0))
            add JumpInstr.new end_label
            add true_label
            add push(num(1))
            add end_label
          end
        when :not then # REWRITE AS BEQ/BNE
          variables(1) do |variable|
            add PopInstr.new variable
            false_label, end_label = LabelInstr.new('false'), LabelInstr.new('end')
            add BNEInstr.new variable, num(0), false_label
            add push(num(1))
            add JumpInstr.new end_label
            add false_label
            add push(num(0))
            add end_label
          end
        when :dup then
          variables(1) do |variable|
            add PopInstr.new(variable)
            add push(variable)
            add push(variable)
          end
        when :cin then
          # Can be written in terms in nin
          variables(1) do |variable|
            add CoutInstr.new string("> ")
            add CinInstr.new variable
            add push(variable)
          end
        when :nin then
          variables(1) do |variable|
            add CoutInstr.new string("Enter an integer: ")
            add NinInstr.new variable
            add push(variable)
          end
        when :swch then
          @in_branch_oper, @in_branch = :swch, -1
        when :roll then
          variables(2) do |variable1, variable2|
            add PopInstr.new variable2
            add PopInstr.new variable1
            add RollInstr.new variable1, variable2
          end
        when :cc then add CopyInstr.new(@cc, num(node.value))
        when :dp then add CopyInstr.new(@dp, num(node.value))
      end
    end

    def bin_op(instr_class)
      variables(2) do |variable1, variable2|
        add PopInstr.new variable2
        add PopInstr.new variable1
        add instr_class.new variable1, variable1, variable2
        add PushInstr.new variable1
      end
    end

    def unary_op(instr_class, result: true)
      variables(1) do |variable1|
        add PopInstr.new(variable1)
        add instr_class.new(variable1)
        add push(variable1) if result
      end
    end
  end
end

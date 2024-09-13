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
      @instructions = []
      @node_mappings = {} # instruction -> node
      @jump_labels = {} # node -> label
      @variable_counter = 0
      @dp, @cc = acquire_variable, acquire_variable
      @current_node = nil
      copy(@dp, num(0), "dp")
      copy(@cc, num(-1), "cc")
    end

    def copy(variable, value, comment=nil)
      add(CopyInstr.new(variable, value).tap do |instr|
        instr.comment = comment if comment
      end)
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
      variable = pop
      variable = plus(@dp, variable)
      @dp = mod(variable, num(4))
      label('end_pntr') do |end_label|
        4.times do |i|
          next_label = i == 3 ? end_label : LabelInstr.new(LabelOperand.new("pntr[#{i}]"))
          add BNEInstr.new @dp, num(i), next_label
          visit(worklist << node.paths[i])
          add next_label unless i == 3
        end
      end

      nil
    end

    def visit_first_swch(node, worklist)
      add NodeInstr.new(node.operation, node.step, node.x, node.y) if DEBUG

      @current_node = node
      result = pop
      result = mod(result, num(2))
      result = pow(num(-1), result)
      result = mult(@cc, result)
      label('swch[-1]') do |next_label|
        add BNEInstr.new(@cc = result, num(-1), next_label)
        visit(worklist << node.paths[0])
      end
      visit(worklist << node.paths[1])
      nil
    end

    def visit_again(node)
      add NodeInstr.new("re-#{node.operation}", node.step, node.x, node.y) if DEBUG
      
      label = @jump_labels[node]

      unless label  # first time to insert label
        label_operand = LabelOperand.new(node.object_id)
        label = LabelInstr.new(label_operand)
        @jump_labels[node] = label
        index = @instructions.find_index(@node_mappings[node])
        if index
        @instructions.insert index, label
        end
      end

      # This will be in proper place because all new nodes are added to
      # end of instruction list.
      add JumpInstr.new label_operand
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
      NumericOperand.new(value)
    end

    def string(value)
      StringOperand.new(value)
    end

    def acquire_variable
      VariableOperand.new("v#{@variable_counter += 1}")
    end

    def jump(label)
      add JumpInstr.new label
    end

    def label(label_name)
      label = LabelInstr.new(LabelOperand.new(label_name))
      yield label.value
      add label
    end

    def mod(operand1, operand2)
      acquire_variable.tap { |result| add ModInstr.new result, operand1, operand2 }
    end

    def mult(operand1, operand2)
      acquire_variable.tap { |result| add MultInstr.new result, operand1, operand2 }
    end

    def plus(operand1, operand2)
      acquire_variable.tap { |result| add AddInstr.new result, operand1, operand2 }
    end

    def pop
      acquire_variable.tap { |variable| add PopInstr.new variable }
    end

    def pow(operand1, operand2)
      acquire_variable.tap { |result| add PowInstr.new result, operand1, operand2 }
    end

    def push(operand)
      add PushInstr.new operand
    end

    def instructions_for(node)
      case node.operation
      when :push then push(num(node.value))
      when :pop then pop
      when :add then bin_op AddInstr
      when :sub then bin_op SubInstr
      when :mult then bin_op MultInstr
      when :div then bin_op DivInstr
      when :mod then bin_op ModInstr
      when :nout then unary_op NoutInstr
      when :cout then unary_op CoutInstr
      when :gtr then
        label('end') do |end_label|
          label('true') do |true_label|
            add GTInstr.new pop, pop, true_label
            push(num(0))
            jump(end_label)
          end
          push(num(1))
        end
      when :not then # REWRITE AS BEQ/BNE
        label('end') do |end_label|
          label('true_test_not') do |true_label|
            add BEQInstr.new pop, num(1), true_label
            push(num(0))
            jump(end_label)
          end
          push(num(1))
        end
      when :dup then
        variable = pop
        push(variable)
        push(variable)
      when :cin then
        # Can be written in terms in nin
        variable = acquire_variable
        add CoutInstr.new string("> ")
        add CinInstr.new variable
        push(variable)
      when :nin then
        variable = acquire_variable
        add CoutInstr.new string("Enter an integer: ")
        add NinInstr.new variable
        push(variable)
      when :swch then
        @in_branch_oper, @in_branch = :swch, -1
      when :roll then
        variable1, variable2 = pop, pop
        add RollInstr.new variable2, variable1
      when :cc then
        copy(@cc = acquire_variable, num(node.value), "cc")
      when :dp then
        copy(@dp = acquire_variable, num(node.value), "dp")
      end
    end

    def bin_op(instr_class)
      variable1, variable2, variable3 = pop, pop, acquire_variable
      add instr_class.new variable3, variable2, variable1
      push(variable3)
    end

    def unary_op(instr_class)
      add instr_class.new(pop)
    end
  end
end

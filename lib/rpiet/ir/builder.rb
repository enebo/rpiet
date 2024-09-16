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
      @current_node = nil
      add DPSetInstr.new(num(0))
      add CCSetInstr.new(num(-1))
    end

    def copy(variable, value, comment=nil)
      add(CopyInstr.new(variable, value).tap do |instr|
        instr.comment = comment if comment
      end)
    end

    def visit_first(node)
      @graph_node = node
      @current_node = node
      instructions_for node
      super node
    end

    def visit_first_pntr(node, worklist)
      # In stack make pntr = (pntr + 1) % 4
      @current_node = node
      @graph_node = node
      variable = pop
      add DPGetInstr.new(dp = acquire_variable)
      variable = plus(dp, variable)
      dp = mod(variable, num(4))
      add DPSetInstr.new(dp)
      label(:"end_pntr#{@graph_node.step}") do |end_label|
        4.times do |i|
          if i == 3
            next_label = end_label
          else
            segment_label = LabelInstr.new(:"pntr[#{i}]#{@graph_node.step}")
            next_label = segment_label.value
          end
          add BNEInstr.new dp, i, next_label
          visit(worklist << node.paths[i])
          @graph_node = node
          add segment_label unless i == 3
        end
      end

      nil
    end

    def visit_first_swch(node, worklist)
      @current_node = node
      @graph_node = node
      result = pop
      result = mod(result, num(2))
      result = pow(num(-1), result)
      add CCGetInstr.new(cc = acquire_variable)
      result = mult(cc, result)
      label(:"swch[-1]#{@graph_node.step}") do |next_label|
        add CCSetInstr.new(result)
        add BNEInstr.new(result, num(-1), next_label)
        visit(worklist << node.paths[0])
      end
      visit(worklist << node.paths[1])
      nil
    end

    def visit_again(node)
      label = @jump_labels[node]
      @graph_node = node

      unless label  # first time to insert label
        label_operand = :"#{node.object_id}"
        label = LabelInstr.new(label_operand)
        @jump_labels[node] = label
        index = @instructions.find_index(@node_mappings[node])
        @instructions.insert index, label if index
      end

      # This will be in proper place because all new nodes are added to
      # end of instruction list.
      jump = JumpInstr.new(label_operand)
      jump.comment = "back to visited #{node} => #{label_operand}"
      add(jump)
    end

    def add(instruction)
      # For first instruction that represents a node from ASG we record it
      # so when we encounter a cycle we know where we should jump.
      if @current_node
        @node_mappings[@current_node] = instruction
        @current_node = nil
      end

      instruction.graph_node = @graph_node

      @instructions << instruction
    end

    def num(value)
      Integer(value)
    end

    def string(value)
      value
    end

    def acquire_variable
      VariableOperand.new("v#{@variable_counter += 1}")
    end

    def jump(label)
      add JumpInstr.new label
    end

    def label(label_name)
      label = LabelInstr.new(label_name)
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
      when :noop then add(NoopInstr.new)
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
        label(:"end#{node.object_id}") do |end_label|
          label(:"true#{node.object_id}") do |true_label|
            add GTInstr.new pop, pop, true_label
            push(num(0))
            jump(end_label)
          end
          push(num(1))
        end
      when :not then # REWRITE AS BEQ/BNE
        label(:"end#{node.object_id}") do |end_label|
          label(:"true_test_not#{node.object_id}") do |true_label|
            add BEQInstr.new pop, num(1), true_label
            push(num(1))
            jump(end_label)
          end
          push(num(0))
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
        add CCSetInstr.new(num(node.value))
      when :dp then
        add DPSetInstr.new(num(node.value))
      when :exit then
        add ExitInstr.new
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

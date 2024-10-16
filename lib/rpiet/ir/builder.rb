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
      add DPInstr.new(num(0))
      add CCInstr.new(num(-1))
    end

    def run(graph)
      super
      # We need to preserve noops while building initial instrs because backward
      # jumps may target the first instr for a graph node and that can be a noop.
      #@instructions.delete_if { |instr| instr.operation == :noop }
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

    # def visit_first_pntr(node, worklist)
    #   # In stack make pntr = (pntr + 1) % 4
    #   @current_node = node
    #   @graph_node = node
    #   variable, dp = pop, acquire_variable
    #   add DPRotateInstr.new(dp, variable)
    #   # FIXME: n paths can go to same location so this should consider emitting to produce less jumps
    #   label(:"end_pntr#{@graph_node.step}") do |end_label|
    #     4.times do |i|
    #       if i == 3
    #         next_label = end_label
    #       else
    #         segment_label = LabelInstr.new(:"pntr[#{i}]#{@graph_node.step}")
    #         next_label = segment_label.value
    #       end
    #       add BNEInstr.new dp, DirectionPointer.from_ordinal(i), next_label
    #       visit(worklist << node.paths[i])
    #       @graph_node = node
    #       add segment_label unless i == 3
    #     end
    #   end
    #
    #   nil
    # end

    def visit_first_pntr(node, worklist)
      # In stack make pntr = (pntr + 1) % 4
      @current_node = node
      @graph_node = node
      variable, dp = pop, acquire_variable
      add DPRotateInstr.new(dp, variable)
      labels = []
      3.times do |i|
        label = LabelInstr.new(:"pntr_#{i}_#{@graph_node.step}")
        add BEQInstr.new dp, DirectionPointer.new(i), label.value
        labels << label
      end
      label = LabelInstr.new(:"pntr_3_#{@graph_node.step}")
      labels << label
      jump label.value

      4.times do |i|
        @graph_node = node
        add labels[i]
        visit(worklist << node.paths[i])
      end
      nil
    end

    def visit_first_swch(node, worklist)
      @current_node = node
      @graph_node = node
      value, cc = pop, acquire_variable
      add CCToggleInstr.new(cc, value)

      # both swch paths goes to same location so eliminate the jumping logic
      if node.paths[0] == node.paths[1]
        visit(worklist << node.paths[0])
      else
        label(:"swch_left_#{@graph_node.step}") do |next_label|
          add BNEInstr.new(cc, CodelChooser::LEFT, next_label)
          visit(worklist << node.paths[0])
        end
        visit(worklist << node.paths[1])
      end
      nil
    end

    def visit_again(node)
      label = @jump_labels[node]
      @graph_node = node

      unless label  # first time to insert label
        label_operand = :"re_#{node.object_id}"
        label = LabelInstr.new(label_operand)
        label.graph_node = node
        @jump_labels[node] = label
        index = @instructions.find_index(@node_mappings[node])
        @instructions.insert index, label if index
      else
        label_operand = label.value
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
      saved_node = @current_node
      label = LabelInstr.new(label_name)
      yield label.value
      @current_node = saved_node
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
        value2, value1, result = pop, pop, acquire_variable
          add GTInstr.new result, value1, value2
        push(result)
      when :not then # REWRITE AS BEQ/BNE
        value1, result = pop, acquire_variable
        add NEInstr.new result, value1, num(0)
        push(result)
      when :dup then
        variable = pop
        push(variable)
        push(variable)
      when :cin then
        # Can be written in terms in nin
        variable = acquire_variable
        add CinInstr.new variable
        push(variable)
      when :nin then
        variable = acquire_variable
        add NinInstr.new variable
        push(variable)
      when :swch then
        @in_branch_oper, @in_branch = :swch, -1
      when :roll then
        variable1, variable2 = pop, pop
        add RollInstr.new variable2, variable1
      when :cc then
        add CCInstr.new(num(node.value))
      when :dp then
        add DPInstr.new(num(node.value))
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

require_relative '../ast/visitor'

module RPiet
  # Visit each node from ASG and translate into simpler more
  # traditional instructions.  These instructions will be
  # translated into different back-ends.
  class Builder < Visitor
    attr_reader :instructions

    def initialize
      super
      @instructions = []
      @node_mappings = {} # instruction -> node
      @variables = []
      @pntr, @cc = acquire_variable, acquire_variable
    end

    # Notes: This is somewhat predicated on having instances because for branching
    # I need to locate the instr in the instruction stream to insert a label in the
    # case of looping.  Fairly extravagant to have an instance with no state just
    # for identity but I am moving a bit too fast and just trying to get this done
    # for a talk.  So I should revisit this at a later date.
    def visit_first(node)
      @current_node = node
      # FIXME: OMG.  This is horrible.  bad visitor design...forward to death
      if @in_branch_oper == :pntr
        @in_branch_oper = nil if @in_branch == 3
        next_label = LabelInstr.new
        add BNEInstr.new @pntr, num(@in_branch), next_label
        @in_branch += 1
      elsif @in_branch_oper == :swch
        @in_branch_oper = nil if @in_branch > 1
        next_label = LabelInstr.new
        add BNEInstr.new @cc, num(@in_branch), next_label
        if @in_branch == -1
          @in_branch = 1
        elsif @in_branch == 1
          @in_branch = 2
        end
      end
      instructions_for node
      add next_label
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

    def visit_again(node)
      label = LabelInstr.new
      index = @instructions.find_index(@node_mappings[node])
      if index == nil
        puts "FFFFFFFFFF: cound not find instructions for #{node}"
      end
      @instructions.insert index, label
      add JumpInstr.new label
    end

    def num(value)
      NumOperand.new(value)
    end

    def string(value)
      StringOperand.new(value)
    end

    def variables(count)
      variables = []
      count.times { variables << acquire_variable }
      yield *variables
    ensure
      variables.each { |variable| return_variable variable }
    end

    def acquire_variable
      @variables.pop || VariableOperand.new
    end

    def return_variable(variable)
      @variables.push variable
    end

    class NumOperand < Struct.new(:value); end
    class StringOperand < Struct.new(:value); end
    class VariableOperand; end

    class NoopInstr; end

    # math instructions
    class AddInstr < Struct.new(:result, :operand1, :operand2); end
    class SubInstr < Struct.new(:result, :operand1, :operand2); end
    class MultInstr < Struct.new(:result, :operand1, :operand2); end
    class DivInstr < Struct.new(:result, :operand1, :operand2); end
    class ModInstr < Struct.new(:result, :operand1, :operand2); end

    # input/output instructions
    class NoutInstr < Struct.new(:operand); end
    class CoutInstr < Struct.new(:operand); end
    class NinInstr < Struct.new(:result); end
    class CinInstr < Struct.new(:result); end

    # instructions which manipulate the stack
    class PopInstr < Struct.new(:result); end
    class PushInstr < Struct.new(:operand); end
    class RollInstr < Struct.new(:operand1, :operand2); end

    # possible jumping instructions
    class JumpInstr < Struct.new(:label); end
    class BEQInstr < Struct.new(:operand1, :operand2, :label); end
    class BNEInstr < Struct.new(:operand1, :operand2, :label); end
    class GTInstr < Struct.new(:operand1, :operand2, :label); end
    class LabelInstr; end

    class CopyInstr < Struct.new(:result, :operand1); end

    def instructions_for(node)
      case node.operation
        when :noop then add NoopInstr.new
        when :push then add PushInstr.new(node.value)
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
            add PopInstr.new variable1
            add PopInstr.new variable2
            false_label, end_label = LabelInstr.new, LabelInstr.new
            add GTInstr.new variable1, variable2, false_label
            add PushInstr num(1)
            add false_label
            add PushInstr num(0)
            add end_label
          end
        when :not then # REWRITE AS BEQ/BNE
          variables(1) do |variable|
            add PopInstr.new variable
            false_label, end_label = LabelInstr.new, LabelInstr.new
            add BNEInstr.new variable, num(0), false_label
            add PushInstr num(1)
            add false_label
            add PushInstr num(0)
            add end_label
          end
        when :dup then
          variables(1) do |variable|
            add PopInstr.new(variable)
            add PushInstr.new(variable)
            add PushInstr.new(variable)
          end
        when :cin then
          # Can be written in terms in nin
          variables(1) do |variable|
            add CoutInstr.new string("> ")
            add CinInstr.new variable
            add PushInstr.new(variable)
          end
        when :nin then
          variables(1) do |variable|
            add CoutInstr.new string("Enter an integer: ")
            add NinInstr.new variable
            add PushInstr.new(variable)
          end
        when :pntr then
          # In stack make pntr = (pntr + 1) % 4
          AddInstr.new @pntr, @pntr, num(1)
          ModInstr.new @pntr, @pntr, num(4)
          @in_branch_oper, @in_branch = :pntr, 0
        when :swch then
          variable(1) do |result|
            else_label, end_label = LabelInstr.new, LabelInstr.new
            add BEQInstr.new @cc, num(1), else_label
            add CopyInstr.new @cc, num(-1)
            add JumpInstr.new end_label
            add else_label
            add CopyInstr.new @cc, num(1)
            add end_label
          end
          @in_branch_oper, @in_branch = :swch, -1
        when :roll then
          variables(2) do |variable1, variable2|
            add PopInstr.new variable1
            add PopInstr.new variable2
            add RollInstr.new variable1, variable2
          end
        when :cc then CopyInstr.new @cc, node.value
        when :dp then CopyInstr.new @dp, node.value
      end
    end

    def bin_op(instr_class)
      variables(2) do |variable1, variable2|
        add PopInstr.new variable1
        add PopInstr.new variable2
        add instr_class.new variable1, variable1, variable2
        add PushInstr.new variable1
      end
    end

    def unary_op(instr_class, result: true)
      variables(1) do |variable1|
        add PopInstr.new variable1
        add instr_class.new variable1, variable1
        add PushInstr.new variable1 if result
      end
    end
  end
end
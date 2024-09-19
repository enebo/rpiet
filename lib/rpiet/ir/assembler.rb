require_relative 'instructions'
require_relative 'operands'

module RPiet
  module IR
    class Assembler
      class << self
        include Instructions, Operands

        def assemble(code)
          instructions = []
          assignments = {}

          code.split($/).each do |line|
            result, rhs = line.split(/\s+=\s+/, 2)
            rhs, result = result, nil unless rhs
            if rhs =~ /\s*(\S+)\s*(==|!=|\*\*|[>\*\/\-%+])\s*(\S+)(?:\s*(\S+))?\s*/
              operation, *operands = $2, *[$1, $3, $4].compact
            else
              operation, *operands = rhs.split(/\s+/)
            end

            instructions << create(assignments, result, operation, *operands)
          end

          instructions
        end

        def create(assignments, result, operation, *operands)
          result = create_assignment(assignments, result) if result
          operands = create_operands(assignments, *operands)

          # Assumes assembly is valid.
          case operation
          when 'push' then PushInstr.new(operands[0])
          when 'dpset' then DPSetInstr.new(operands[0])
          when 'ccset' then CCSetInstr.new(operands[0])
          when 'pop' then PopInstr.new(result)
          when 'dpget' then DPGetInstr.new(result)
          when 'ccset' then CCGetInstr.new(result)
          when '+' then AddInstr.new(result, *operands)
          when '-' then SubInstr.new(result, *operands)
          when '*' then MultInstr.new(result, *operands)
          when '/' then DivInstr.new(result, *operands)
          when '%' then ModInstr.new(result, *operands)
          when '**' then PowInstr.new(result, *operands)
          when 'nout' then NoutInstr.new(*operands)
          when 'cout' then CoutInstr.new(*operands)
          when '>' then GTInstr.new(*operands)
          when '==' then BEQInstr.new(*operands)
          when '!=' then BNEInstr.new(*operands)
          when 'jump' then JumpInstr.new(*operands)
          when 'cin' then CinInstr.new(result)
          when 'nin' then NinInstr.new(result)
          when 'roll' then RollInstr.new *operands
          when 'copy' then CopyInstr.new(result, *operands)
          when 'label' then LabelInstr.new(*operands)
          when 'exit' then ExitInstr.new
          else
            raise ArgumentError.new("unknown operation: #{operation}")
          end
        end

        def create_assignment(assignments, result)
          raise ArgumentError.new("result must be variable") unless result[0] == 'v'
          raise ArgumentError.new("Same assignment found: #{result}.  Not in SSA form") if assignments[result]
          assignments[result] = VariableOperand.new(result)
        end

        def create_operands(assignments, *operands)
          operands.map do |operand|
            case operand[0]
            when 'v' then
              variable = assignments[operand]
              raise ArgumentError.new("Variable without assignment found: #{operand}.  Not in SSA form") unless variable
              variable
            when /\d/ then Integer(operand)
            when '\'' then operand[1..-2]
            when /\S/ then operand.to_sym
            else raise ArgumentError.new("unknown operand: #{operand}")
            end
          end
        end
      end
    end
  end
end
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
            result, rhs = line.split(/\s*=\s*/, 2)
            rhs, result = result, nil unless rhs
            if rhs =~ /\s*(\S+)\s*(==|!=|\*\*|[>\*\/\-%+])\s*(\S+)(?:\s*(\S+))?\s*/
              operation, *operands = $2, *[$1, $3, $4].compact
            else
              operation, *operands = rhs.split(/\s+/)
            end

            instr = create(result, operation, *operands)

            if instr.respond_to?(:result)
              result = instr.result
              raise ArgumentError.new("Same assignment found #{result}.  Not in SSA form") if assignments[result]
              assignments[result] = true
            end
            
            instructions << instr
          end

          instructions
        end

        def create(result, operation, *operands)
          result = create_operands(result).first if result
          operands = create_operands(*operands)

          # Assumes assembly is valid.
          case operation
          when 'push' then PushInstr.new(operands[0])
          when 'pop' then PopInstr.new(result)
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
          else
            raise ArgumentError.new("unknown operation: #{operation}")
          end
        end

        def create_operands(*operands)
          operands.map do |operand|
            case operand[0]
            when 'v' then VariableOperand.new(operand)
            when /\d/ then NumericOperand.new(Integer(operand))
            when '\'' then StringOperand.new(operand[1..-1])
            when /\S/ then LabelOperand.new(operand)
            else raise ArgumentError.new("unknown operand: #{operand}")
            end
          end
        end
      end
    end
  end
end
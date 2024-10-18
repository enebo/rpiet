require_relative 'ir_interpreter'

module RPiet
  module IR
    class IRNativeInterpreter < IRInterpreter
      def process_image(image)
        graph = RPiet::ASG::Parser.new(image).run
        builder = RPiet::Builder.new
        builder.run graph
        @instructions = builder.instructions
        @cfg = CFG.new(@instructions)
        @instructions = @cfg.instructions(Passes::Peephole)
        # Note: left over from experiment but pop or push with n will construct an array and this outweighs the benefit
        # combine_pushes_and_pops
        generate_ruby_bb_methods
      end

      def run
        method_name = :entry
        while method_name do
          method_name = send(method_name)
        end
      end

      private

      def generate_ruby_bb_methods
        # Generate constants and things generated methods may rely on.
        @instructions.each { |instr| eval instr.to_ruby_pre if instr.respond_to?(:to_ruby_pre) }

        @cfg.basic_blocks.each do |bb|
          s = ["def #{bb.label}()\n"]
          bb.instrs.each do |instr|
            lines = instr.to_ruby(@cfg, bb)
            s << lines if lines
          end
          unless bb.instrs&.last&.jump?
            ret = @cfg.outgoing_target(bb, :fall_through)&.label || 'nil'
            s << "  #{ret}\n"
          end
          s << "end\n"
          code = s.join('')
          puts "#{code}\n"
          self.instance_eval code
          if bb.instrs&.first.kind_of?(Instructions::LabelInstr)
            bb.instrs.pop(bb.instrs.length - 1)
          else
            bb.instrs.clear
          end
        end
      end

      def combine_pushes_and_pops
        @cfg.basic_blocks.each { |bb| multi_opt(Instructions::MultiplePushInstr, bb, :push, :operand) }
        @cfg.basic_blocks.each { |bb| multi_opt(Instructions::MultiplePopInstr, bb, :pop, :result) }
      end

      def multi_opt(instr_type, bb, operation, field)
        list = []
        bb.instrs.each_with_index do |instr, i|
          if instr.operation == operation
            list << instr
          else
            if list.length > 1
              bb.instrs[(i - list.length)...i] = instr_type.new(*list.map { |instr| instr.send(field) }.reverse)
            end
            list = []
          end
        end
        if list.length > 1
          bb.instrs[(bb.instrs.length - list.length)..-1] = instr_type.new(*list.map { |instr| instr.send(field) }.reverse)
        end
      end
    end
  end
end
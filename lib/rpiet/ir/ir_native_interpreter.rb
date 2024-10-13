require_relative 'ir_interpreter'

module RPiet
  module IR
    class IRNativeInterpreter < IRInterpreter
      def process_image(image)
        graph = RPiet::ASG::Parser.new(image).run
        builder = RPiet::Builder.new
        builder.run graph
        @instructions = builder.instructions
        puts "(initial) # of instr: #{@instructions.length}"
        #puts "INSTRS:\n#{@instructions.map {|i| i.disasm }.join("\n")}"
        @cfg = CFG.new(@instructions)
        @instructions = @cfg.instructions(Passes::Peephole)
        @cfg.basic_blocks.each do |bb|
          pushes = []
          bb.instrs.each_with_index do |instr, i|
            if instr.operation == :push
              pushes << instr
            else
              if pushes.length > 1
                bb.instrs[(i - pushes.length)...i] = Instructions::MultiplePushInstr.new(*pushes.map { |instr| instr.operand })
              end
              pushes = []
            end
          end
          if pushes.length > 1
            bb.instrs[(bb.instrs.length - pushes.length)..-1] = Instructions::MultiplePushInstr.new(*pushes.map { |instr| instr.operand })
          end
        end

        @cfg.basic_blocks.each do |bb|
          pops = []
          bb.instrs.each_with_index do |instr, i|
            if instr.operation == :pop
              pops << instr
            else
              if pops.length > 1
                bb.instrs[(i - pops.length)...i] = Instructions::MultiplePopInstr.new(*pops.map { |instr| instr.result }.reverse)
              end
              pops = []
            end
          end
          if pops.length > 1
            bb.instrs[(bb.instrs.length - pops.length)..-1] = Instructions::MultiplePopInstr.new(*pops.map { |instr| instr.result }.reverse)
          end
        end
        @instructions.each do |instr|
          self.instance_eval instr.to_ruby_pre if instr.respond_to?(:to_ruby_pre)
        end
        @cfg.basic_blocks.each do |bb|
          s = ["def #{bb.label}()\n"]
          bb.instrs.each do |instr|
            s << instr.to_ruby(@cfg, bb)
            #puts "instr: #{instr.disasm}, r: #{instr.to_ruby(cfg, bb)}"
          end
          unless bb.instrs&.last&.jump?
            target = @cfg.outgoing_target(bb, :fall_through)&.label
            line = target ? target : 'nil'
            s << "#{line}\n"
          end
          s << "end\n"
          code = s.join('')
          puts "#{bb.label}:\n#{code}"
          #mega = MegaInstr.new
          self.instance_eval code
          if bb.instrs&.first.kind_of?(Instructions::LabelInstr)
            bb.instrs.pop(bb.instrs.length - 1)
          else
            bb.instrs.clear
          end
          #bb.instrs << mega
          #          Instructions::MegaInstr.create(self, @cfg, bb)
        end
      end

      def run
        method_name = :entry
        while method_name do
          method_name = send(method_name)
        end
      end
    end
  end
end
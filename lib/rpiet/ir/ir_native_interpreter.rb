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
          Instructions::MegaInstr.create(bb)
        end
        @instructions = @cfg.instructions(Passes::Peephole)
        @cfg.write_to_dot_file
        puts "(post) # of instr: #{@instructions.length}"
        #puts "INSTRS:\n#{@instructions.map { |i| i.disasm }.join("\n")}"
      end
    end
  end
end
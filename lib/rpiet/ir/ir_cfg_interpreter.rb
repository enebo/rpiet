require_relative 'ir_interpreter'
require_relative 'cfg'
require_relative 'passes/peephole'

module RPiet
  module IR
    class IRCFGInterpreter < IRInterpreter
      def process_image(image)
        graph = RPiet::ASG::Parser.new(image).run
        builder = RPiet::Builder.new
        builder.run graph
        @instructions = builder.instructions
        puts "(initial) # of instr: #{@instructions.length}"
        @cfg = CFG.new(@instructions)
        @instructions = @cfg.instructions(Passes::Peephole)
        @cfg.write_to_dot_file
        puts "(post) # of instr: #{@instructions.length}"
      end

      def disasm = @instructions.each { |instr| puts instr.disasm }
    end
  end
end
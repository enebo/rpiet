require 'rpiet/direction_pointer'
require 'rpiet/codel_chooser'

module RPiet
  ## 
  # This is a simple piet runtime to be controled by interp.
  #
  # dp - Direction Pointer (right, down, left, up)
  # cc - Codel Chooser (left, right)
  class Machine
    attr_reader :dp, :cc, :stack
    attr_accessor :block_value

    def initialize
      @stack, @dp, @cc = [], DirectionPointer.new, CodelChooser.new
      @block_value = 1
    end
     
    def noop; end
    def push;  @stack << @block_value; end
    def pop; @stack.pop; end

    def add; math_op :+; end
    def sub; math_op :-; end
    def mult; math_op :*; end
    def div; math_op :/; end
    def mod; math_op :%; end

    def gtr; bin_op { |a, b| @stack << (a > b ? 1 : 0) }; end
    def not; unary_op { |top| @stack << (!top || top == 0 ? 1 : 0) }; end
    def dup; @stack << @stack[-1]; end
    def nout; unary_op { |top| print top }; end
    def cout; unary_op { |top| print top.chr }; end
    def pntr; unary_op { |top| @dp.rotate! top }; end
    def swch; unary_op { |top| @cc.switch! top }; end
    def n_in; puts "Enter an integer: "; @stack << $stdin.gets.to_i; end
    def c_in; puts "> "; @stack << $stdin.read(1).to_i; end
    def roll
      bin_op do |depth, num| 
        num %= depth
        return if depth <= 0 || num == 0
        x = -num.abs + depth * (num < 0 ? 0 : 1)
        @stack[-depth..-1] = @stack[-x..-1] + @stack[-depth...-x]
      end
    end

    def inspect
      "DP: #{@dp}, CC: #{@cc}, BV: #{@block_value}, STACK: #{@stack}"
    end
    alias :to_s :inspect

    private
    def bin_op(&block)
      return unless @stack.length >= 2
      block.call *@stack.pop(2)
    end
    
    def unary_op(&block)
      return unless @stack.length >= 1
      block.call(@stack.pop)
    end

    def math_op(op); bin_op { |a, b| @stack << a.send(op, b) }; end
  end
end

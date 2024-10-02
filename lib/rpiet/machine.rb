require_relative 'direction_pointer'
require_relative 'codel_chooser'
require_relative 'live_machine_state'

module RPiet
  # Using the value npiet decided to use if division by zero happens.
  DIV_BY_ZERO_VALUE = 99999999

  ## 
  # This is a simple piet runtime to be controled by interp.
  #
  # dp - Direction Pointer (right, down, left, up)
  # cc - Codel Chooser (left, right)
  class Machine
    ##
    # Each group's size represents a block value which can be used by the push operation.
    attr_accessor :block_value

    include LiveMachineState

    def initialize
      reset_machine
      @block_value = 1
    end

    ##
    # Return the next possible location based on direction pointers facing
    def next_possible(x, y)
      @dp.next_possible(x, y)
    end

    ##
    # Change either codel chooser or direction pointer to try and look
    # at a different codel.
    def orient_elsewhere(attempt)
      if attempt.even?
        dp.rotate!
      else
        cc.switch!
      end
    end
     
    def noop; end
    def push;  @stack << @block_value; end
    def pop; @stack.pop; end

    def add; math_op :+; end
    def sub; math_op :-; end
    def mult; math_op :*; end

    # Note: Following npiet's div by zero value.
    def div = bin_op { |a, b| @stack << (b == 0 ? DIV_BY_ZERO_VALUE : a / b) }

    def mod; math_op :%; end

    def gtr; bin_op { |a, b| @stack << (a > b ? 1 : 0) }; end
    def not; unary_op { |top| @stack << (!top || top == 0 ? 1 : 0) }; end
    def dup; @stack << @stack[-1] if @stack[-1]; end
    def nout; unary_op { |top| print top }; end
    def cout; unary_op { |top| print top.chr }; end
    def pntr; unary_op { |top| @dp.rotate! top }; end
    def swch; unary_op { |top| @cc.switch! top }; end
    def nin; puts "Enter an integer: "; @stack << $stdin.gets.to_i; end
    def cin; $stdout.write "> "; c = $stdin.read(1).ord; @stack << c; end
    def roll
      bin_op do |depth, num|
        num %= depth
        return if depth <= 0 || num == 0
        if num > 0
          @stack[-depth..-1] = @stack[-num..-1] + @stack[-depth...-num]
        elsif num < 0
          @stack[-depth..-1] = @stack[-depth...-num] + @stack[-num..-1]
        end
      end
    end

    def inspect
      super + ", bv: #@block_value"
    end
    alias :to_s :inspect

    ##
    # Execute the operation represented by the two colors
    def execute(color1, color2)
      operation = calculate_operation(color1, color2)
      __send__(operation)
      operation
    end

    def calculate_operation(color1, color2)
      dh = color1.hue.delta color2.hue
      dd = color1.lightness.delta color2.lightness
      OPERATION[dh][dd]
    end

    private
    def bin_op(&block)
      return unless @stack.length >= 2
      block.call *@stack.pop(2)
    end
    
    def unary_op(&block)
      return if @stack.length < 1
      block.call(@stack.pop)
    end

    def math_op(op); bin_op { |a, b| @stack << a.send(op, b) }; end

    ##
    #                     Lightness change
    #Hue change     None         1 Darker     2 Darker
    #  None                      push         pop
    # 1 Step        add          subtract     multiply
    # 2 Steps       divide       mod          not
    # 3 Steps       greater      pointer      switch
    # 4 Steps       duplicate    roll         in(number)
    # 5 Steps       in(char)     out(number)  out(char)
    #
    OPERATION = [[:noop, :push, :pop],
                 [:add,  :sub, :mult],
                 [:div,  :mod, :not],
                 [:gtr,  :pntr, :swch],
                 [:dup,  :roll, :nin],
                 [:cin, :nout, :cout]]
  end
end

module RPiet
  class Cycle
    attr_reader :type, :value
    attr_accessor :length

    def initialize(value, name, list)
      @value, @name, @list = value, name.to_s.downcase, list
    end

    def delta(other)
      (@value - other.value) % @length
    end

    def -(other)
      @list[(@value - other.value) % @length]
    end

    def +(other)
      @list[(@value + other.value) % @length]
    end

    def incr(amount = 1)
      @list[(@value + amount) % @length]
    end

    def decr(amount = 1)
      @list[(@value - amount) % @length]
    end

    def abs(amount)
      @list[amount % @length]
    end

    def to_initial
      @name[0]
    end

    def to_s
      "#{@name}"
    end
    
    def inspect
      "#{@name}(#{@value})"
    end
  end

  module CycleMethod
    ##
    # Define a constant in self and then populate a series of constants
    # within that with cycled values from 0-n.
    def cycle(const_name, *names)
      
      list = []
      if const_name.is_a? Symbol
        holder_module = Module.new
        const_set const_name, holder_module 
      else
        holder_module = const_name
      end
      names.each_with_index do |name, i|
        list[i] = Cycle.new(i, name, list)
        holder_module.const_set name, list[i]
      end

      # Micro-opt...@list.length is slower than @length
      list.each { |element| element.length = list.length}
    end
    module_function :cycle
  end
end

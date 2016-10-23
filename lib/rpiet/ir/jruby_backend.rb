require 'jruby'
require_relative '../parser/parser'
require_relative 'builder'

module Kernel
  # returns a lambda containing the piet program loaded
  def piet_require(filename, codel_size=1)
    if filename =~ /.txt/
      require_relative '../image/ascii_image'
      image = RPiet::Image::AsciiImage.new(File.read(filename), codel_size)
    else
      filename = 'file:' + filename if File.exist? filename
      require_relative '../image/url_image'
      image = RPiet::Image::URLImage.new(filename, codel_size)
    end

    graph = RPiet::Parser.new(image).run
    builder = RPiet::Builder.new
    builder.run graph
    puts builder.instructions.join("\n")
    puts "Done"
    runtime = JRuby.runtime
    tc = runtime.current_context
    scope = RPiet::JRubyBackend.new(runtime.getIRManager, tc.current_static_scope).build(builder.instructions, builder.cc, builder.dp)
    
    body = scope.block_body
    block = org.jruby.runtime.Block.new(body, tc.currentBinding(runtime.object, tc.current_scope))

    #set_trace_func proc { |event, *e| p e if event.to_s == "call" }

    org.jruby.RubyProc.newProc(runtime, block, org.jruby.runtime.Block::Type::LAMBDA, filename, 0)
  end

  #public :p
end

class Array
  def roll(depth, num)
    num %= depth
    return if depth <= 0 || num == 0
    if num > 0
      self[-depth..-1] = self[-num..-1] + self[-depth...-num]
    elsif num < 0
      self[-depth..-1] = self[-depth...-num] + self[-num..-1]
    end
  end
end

module RPiet
  class JRubyBackend
    java_import org.jruby.parser.StaticScope
    java_import org.jruby.parser.StaticScopeFactory
    java_import org.jruby.runtime.ArgumentDescriptor
    java_import org.jruby.runtime.ArgumentType
    java_import org.jruby.runtime.CallType
    java_import org.jruby.runtime.RubyEvent
    java_import org.jruby.runtime.Signature
    java_import org.jruby.ir.Operation
    java_import org.jruby.ir.IRClosure
    java_import org.jruby.ir.instructions.BEQInstr
    java_import org.jruby.ir.instructions.BNEInstr
    java_import org.jruby.ir.instructions.CallInstr
    java_import org.jruby.ir.instructions.CheckArityInstr
    java_import org.jruby.ir.instructions.JumpInstr
    java_import org.jruby.ir.instructions.LabelInstr
    java_import org.jruby.ir.instructions.NopInstr
    java_import org.jruby.ir.instructions.NoResultCallInstr
    java_import org.jruby.ir.instructions.ReceivePreReqdArgInstr
    java_import org.jruby.ir.instructions.ReturnInstr
    java_import org.jruby.ir.instructions.TraceInstr
    java_import org.jruby.ir.operands.CurrentScope
    java_import org.jruby.ir.operands.Operand
    java_import org.jruby.ir.operands.ScopeModule
    java_import org.jruby.ir.operands.StringLiteral
    java_import org.jruby.ir.operands.TemporaryLocalVariable
    java_import org.jruby.ir.operands.UnexecutableNil

    class NamedTemporaryVariable < TemporaryLocalVariable
      def initialize(index, name)
        super(index)
        @name = name
      end

      def getPrefix
        @name
      end
    end

    def initialize(manager, containing_scope)
      @manager = manager
      "_in".to_java(:String).intern
      "_out".to_java(:String).intern
      param_names = ["_in", "_out"].to_java java.lang.String
      static_scope = StaticScopeFactory.new_static_scope(containing_scope, StaticScope::Type::BLOCK, param_names, -1)
      @scope = IRClosure.new(@manager, containing_scope.getIRScope, 0,
                             static_scope, Signature::TWO_ARGUMENTS)
      @instructions = java.util.ArrayList.new
      @variables = {} # piet -> jruby
      @labels = {} # piet -> jruby
    end

    def add(instr)
      @instructions.add instr
    end

    # Note: originally considered fully boxing by default but VM
    # should be responsible so this is a call (plus this is way simpler)
    def alu_op(instr)
      add call(instr.result, instr.operand1, instr.oper, instr.operand2)
    end

    def call(result, receiver, name, *args)
      if result
        CallInstr.create(@scope, CallType::NORMAL, build_operand(result), name.to_s,
                         build_operand(receiver), build_operands(*args).to_java(Operand), nil)
      else
        recv = build_operand(receiver)
        operands = build_operands(*args)
        NoResultCallInstr.create(CallType::NORMAL, name.to_s, recv, operands.to_java(Operand),
                                 nil, false)
      end
    end
    
    def copy(a,b)
      org.jruby.ir.instructions.CopyInstr.new build_operand(a), build_operand(b)
    end

    def build_operands(*operands)
      operands.inject([]) do |array, operand|
        array << build_operand(operand)
        array
      end
    end

    def build_operand(operand)
      return operand if operand.kind_of? Operand

      case operand.name
      when :var then
        temp_var_for(operand)
      when :string then
        StringLiteral.new operand.value
      when :num then num(operand.value)
      end
    end

    def label(piet_label)
      @labels[piet_label] = @scope.get_new_label(piet_label.value)  unless @labels[piet_label]
      @labels[piet_label]
    end

    def num(value)
      org.jruby.ir.operands.Fixnum.new value
    end

    def temp_var_for(variable)
      @variables[variable] = temp_var unless @variables[variable]
      @variables[variable]
    end
    
    def temp_var
      @scope.create_temporary_variable
    end

    def build(piet_instructions, cc, dp)
      build_prologue
      build_args
      build_pointers(cc, dp)
      return_value = build_body(piet_instructions)
      build_return return_value
      @scope.allocateInterpreterContext @instructions
      @scope      
    end

    # 2 args (in, out)
    def build_args
      @scope.argument_descriptors = build_arg_descriptor
      add CheckArityInstr.new(2, 0, false, false, -1)
      _in = @scope.get_new_local_variable("_in", 0)
      add ReceivePreReqdArgInstr.new(_in, 0)
      _out = @scope.get_new_local_variable("_out", 0)
      add ReceivePreReqdArgInstr.new(_out, 1)
    end

    def build_body(piet_instrs)
      temp_var = temp_var() # we generally only need one and can reuse it.
      input = @scope.lookupExistingLVar("_in")
      output = @scope.lookupExistingLVar("_out")
      stack_var = build_stack
      piet_instrs.each do |instr|
        next unless instr
        case instr.name
        when :noop
          add NopInstr.NOP
        when :add, :sub, :mult, :div, :mod, :pow then alu_op(instr)
        when :push
          add call(nil, stack_var, :push, instr.operand)
        when :pop
          add call(instr.result, stack_var, :pop)
        when :roll
          add call(nil, stack_var, :roll, instr.operand1, instr.operand2)
        when :cin
          add call(instr.result, input, :read, num(1))
        when :nin
          add call(temp_var, input, :gets)
          add call(nil, output, :puts, temp_var)
          add call(instr.result, temp_var, :to_i)
        when :cout
          add call(temp_var, instr.operand, :chr)
          add call(nil, output, :print, temp_var)
        when :nout
          add call(nil, output, :print, instr.operand)
        when :jump
          add JumpInstr.new label(instr.label)
        when :beq
          add BEQInstr.create(*build_operands(instr.operand1, instr.operand2),
                              label(instr.label))
        when :bne
          add BNEInstr.create(label(instr.label),
                              *build_operands(instr.operand1, instr.operand2))
        when :gt
          add call(temp_var, instr.operand2, :>, instr.operand1)
          add BNEInstr.create(label(instr.label), temp_var, @manager.true)
        when :label
          add LabelInstr.new(label(instr))
        when :copy
          add copy(instr.result, instr.operand)
        when :node
          add TraceInstr.new(RubyEvent::CALL, instr.to_s, "", -1)
        end
      end
      add call(temp_var, stack_var, :pop)
      temp_var
    end

    # Made custom-named type so we get better output in JRuby IR
    # so we can more easily recognize special locals
    def build_pointers(cc, dp)
      cc_operand = build_operand(cc)
      @variables[cc] = NamedTemporaryVariable.new cc_operand.offset, '%cc'
      dp_operand = build_operand(dp)
      @variables[dp] = NamedTemporaryVariable.new dp_operand.offset, '%dp'
    end

    # will be our live stack during execution.
    # Note: JRuby IR has no primitives for manipulating arrays
    # directly so we will be leveraging Ruby internally for
    # stack manipulation
    def build_stack
      t = temp_var # alloc temp but the take it over with named one
      NamedTemporaryVariable.new(t.offset, '%stack').tap do |stack_var|
        add copy(stack_var, org.jruby.ir.operands.Array.new)
      end
    end

    def build_arg_descriptor
      [ArgumentDescriptor.new(ArgumentType.req, "_in"),
       ArgumentDescriptor.new(ArgumentType.req, "_out")].to_java(ArgumentDescriptor)
    end

    def build_prologue
      add @manager.receive_self_instr
      add copy(@scope.current_scope_variable, CurrentScope::CURRENT_SCOPE[0])
      add copy(@scope.current_module_variable, ScopeModule::SCOPE_MODULE[0])
    end

    def build_return(return_value)
      if return_value && return_value != UnexecutableNil::U_NIL
        add ReturnInstr.new(return_value)
      end
      # Note: I am ignoring all special handling logic for lambda here
      # because I know I have no need for it but I wonder if JRuby IR
      # will choke on this lack of support regardless?
    end
  end
end

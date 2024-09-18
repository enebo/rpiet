require_relative 'spec_helper'
require_relative '../lib/rpiet/asg/graph_interpreter'
require_relative '../lib/rpiet/interpreter'

describe "RPiet Runtimes" do

  let(:push_pop) do # [push 2, pop]*
    create_image <<-EOS
nb db ++
nb ++ ++
++ ++ ++
    EOS
  end

  let(:push_add) do # [push 2, push 1, add, ...]
    create_image <<-EOS
nb db lb lm ++
nb ++ ++ lm ++
++ ++ ++ ++ ++
    EOS
  end

  let(:push_subtract) do # [push 2, push 1, subtract, ...]
    create_image <<-EOS
nb db lb nm ++
nb ++ ++ nm ++
++ ++ ++ ++ ++
    EOS
  end

  let(:push_multiply) do # [push 2, push 2, multiply, ...]
    create_image <<-EOS
nb db lb dm ++
nb db ++ dm ++
++ ++ ++ ++ ++
    EOS
  end

  let(:push_divide) do # [push 2, push 2, divide, ...]
    create_image <<-EOS
nb db lb lr ++
nb db ++ lr ++
++ ++ ++ ++ ++
    EOS
  end

  let(:push_mod) do # [push 2, push 2, mod, ...]
    create_image <<-EOS
nb db lb nr ++
nb db ++ nr ++
++ ++ ++ ++ ++
    EOS
  end

  let(:push_not) do # [push 2, push 2, mod, not, ...]
    create_image <<-EOS
nb db lb nr lg ++
nb db ++ nr lg ++
++ ++ ++ ++ ++ ++
    EOS
  end

  let(:skip_white) do
    create_image <<-EOS
nb .. .. db ++
nb .. .. ++ ++
++ .. .. ++ ++
    EOS
  end

  [RPiet::Interpreter, RPiet::ASG::GraphInterpreter].each do |runtime|
    describe runtime do
      it "Can push and pop" do
        interpreter = runtime.new push_pop
        interpreter.reset
        interpreter.next_step
        expect(interpreter.stack).to eq [2]
        interpreter.next_step
        expect(interpreter.stack).to eq []
      end

      it "Can push and add" do
        interpreter = runtime.new push_add
        interpreter.reset
        interpreter.next_step
        interpreter.next_step
        expect(interpreter.stack).to eq [2, 1]
        interpreter.next_step
        expect(interpreter.stack).to eq [3]
      end

      it "Can push and subtract" do
        interpreter = runtime.new push_subtract
        interpreter.reset
        interpreter.next_step
        interpreter.next_step
        expect(interpreter.stack).to eq [2, 1]
        interpreter.next_step
        expect(interpreter.stack).to eq [1]
      end

      it "Can push and multiply" do
        interpreter = runtime.new push_multiply
        interpreter.reset
        interpreter.next_step
        interpreter.next_step
        expect(interpreter.stack).to eq [2, 2]
        interpreter.next_step
        expect(interpreter.stack).to eq [4]
      end

      it "Can push and divide" do
        interpreter = runtime.new push_divide
        interpreter.reset
        interpreter.next_step
        interpreter.next_step
        expect(interpreter.stack).to eq [2, 2]
        interpreter.next_step
        expect(interpreter.stack).to eq [1]
      end

      it "Can push and mod" do
        interpreter = runtime.new push_mod
        interpreter.reset
        interpreter.next_step
        interpreter.next_step
        expect(interpreter.stack).to eq [2, 2]
        interpreter.next_step
        expect(interpreter.stack).to eq [0]
      end

      it "Can push and not" do
        interpreter = runtime.new push_not
        interpreter.reset
        interpreter.next_step
        interpreter.next_step
        expect(interpreter.stack).to eq [2, 2]
        interpreter.next_step
        interpreter.next_step
        expect(interpreter.stack).to eq [1]
      end

      it "Can skip white and push and pop" do
        interpreter = runtime.new push_pop
        interpreter.reset
        interpreter.next_step
        expect(interpreter.stack).to eq [2]
        interpreter.next_step
        expect(interpreter.stack).to eq []
      end
    end
  end
end

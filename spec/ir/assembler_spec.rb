require_relative '../spec_helper'

include RPiet::IR::Instructions

describe "RPiet::IR::Assembler" do
  context "individual instructions" do
    it "can load copy" do
      instr = assemble("v1 = copy 1\n").first
      expect(instr.operation).to eq(:copy)
      expect(instr.operands[0]).to be_numeric_operand(1)
      expect(instr.result).to be_variable_operand("v1")
    end

    it "can load push" do
      instr = assemble("push 10\n").first
      expect(instr.operation).to eq(:push)
      expect(instr.operands[0]).to be_numeric_operand(10)
    end

    it "can load pop" do
      instr = assemble("v1 = pop\n").first
      expect(instr.operation).to eq(:pop)
      expect(instr.result).to be_variable_operand("v1")
    end

    it "can load nout" do
      instr = assemble("nout 12\n").first
      expect(instr.operation).to eq(:nout)
      expect(instr.operands[0]).to be_numeric_operand(12)
    end

    it "can load cout" do
      instr = assemble("cout 'a'\n").first
      expect(instr.operation).to eq(:cout)
      expect(instr.operands[0]).to be_string_operand("a")
    end

    it "can load nin" do
      instr = assemble("v1 = nin\n").first
      expect(instr.operation).to eq(:nin)
      expect(instr.result).to be_variable_operand("v1")
    end

    it "can load roll" do
      instr = assemble("roll 1 10\n").first
      expect(instr.operation).to eq(:roll)
      expect(instr.operands[0]).to be_numeric_operand(1)
      expect(instr.operands[1]).to be_numeric_operand(10)
    end

    context "can load infix math" do
      %w[+ - * / % **].zip(%i[add sub mult div mod pow]).each do |oper, type|
        it "can load #{oper}" do
          instr = assemble("v1 = copy 2\nv2 = 1 #{oper} v1\n")[1]
          expect(instr.operation).to eq(type)
          expect(instr.operands[0]).to be_numeric_operand(1)
          expect(instr.operands[1]).to be_variable_operand("v1")
          expect(instr.result).to be_variable_operand("v2")
        end
      end
    end

    context "can process branches" do
      %w[> != ==].zip(%i[gt bne beq]).each do |oper, type|
        it "can load #{oper}" do
          instr = assemble("v2 = 1 #{oper} 2 label\n").first
          expect(instr.operation).to eq(type)
          expect(instr.operands[0]).to be_numeric_operand(1)
          expect(instr.operands[1]).to be_numeric_operand(2)
          expect(instr.label).to be_label_operand("label")
        end
      end
    end

    it "can load jump" do
      instr = assemble("jump label\n").first
      expect(instr.operation).to eq(:jump)
      expect(instr.label).to be_label_operand("label")
    end

    it "can load multiple instructions" do
      instrs = assemble("push 10\nv1 = pop\n")
      expect(instrs.size).to eq(2)
      expect(instrs[0].operation).to eq(:push)
      expect(instrs[1].operation).to eq(:pop)
    end

    it "is in single-static-assignment form (SSA)" do
      expect { assemble("v1 = pop\nv2 = pop\nv1 = pop\n") }.to raise_error(ArgumentError)
      expect { assemble("push v1\n") }.to raise_error(ArgumentError)
    end
  end
end

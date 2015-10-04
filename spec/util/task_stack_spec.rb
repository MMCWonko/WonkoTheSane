require 'spec_helper'

require 'wonko_the_sane/util/task_stack'

describe WonkoTheSane::Util::TaskStack do
  let(:stack) { described_class.new }

  context '.new' do
    it 'initializes with an empty queue' do
      expect(stack.queue).to be_empty
    end
  end

  context '#push' do
    it 'adds to the queue' do
      expect { stack.push Proc.new {} }.to change(stack.queue, :size).by 1
    end
  end

  context '#push_defered' do
    it 'adds to the queue' do
      expect { stack.push_defered Proc.new {} }.to change(stack.queue, :size).by 1
    end
  end

  context '#pop' do
    it 'reduces the queue size' do
      stack.push Proc.new {}
      expect { stack.pop }.to change(stack.queue, :size).by -1
    end

    it 'calls the top item' do
      expect { |b|
        stack.push Proc.new {}
        stack.push Proc.new &b
        stack.pop
      }.to yield_control
    end
  end

  context '#pop_all' do
    it 'empties the queue' do
      stack.push Proc.new {}
      stack.push Proc.new {}
      stack.push Proc.new {}
      expect { stack.pop_all }.to change(stack.queue, :size).by -3
    end

    it 'calls all items' do
      expect { |b|
        stack.push Proc.new &b
        stack.push Proc.new &b
        stack.push Proc.new &b
        stack.pop_all
      }.to yield_control.exactly(3).times
    end
  end

  context '#in_background' do
    it 'empties the queue' do
      stack.push Proc.new {}
      stack.push Proc.new {}
      stack.push Proc.new {}
      expect { stack.in_background {} }.to change(stack.queue, :size).by -3
    end

    it 'runs the given block' do
      expect { |b|
        stack.in_background &b
      }.to yield_with_no_args
    end

    it 'returns the result of the block' do
      expect(stack.in_background { 42 }).to eq 42
    end
  end
end

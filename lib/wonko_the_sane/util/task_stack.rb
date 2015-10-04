module WonkoTheSane
  module Util
    class TaskStack
      attr_reader :queue

      def initialize
        @queue = []
      end

      def push(task)
        @queue.push task
      end
      def push_defered(task)
        @queue.unshift task
      end
      def pop
        task = @queue.pop
        task.call
      end
      def pop_all
        pop until @queue.empty?
      end
      def in_background(&block)
        thread = Thread.new &block
        pop_all
        thread.join.value
      end
    end
  end
end

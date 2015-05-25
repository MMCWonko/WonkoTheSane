require 'benchmark'

module WonkoTheSane
  module Util
    class Benchmark
      def initialize
        @timers = {}
        @calls = {}
      end

      def benchmark(id, &block)
        @timers[id.to_s] ||= ::Benchmark::Tms.new(0, 0, 0, 0, 0, id.to_s)
        @calls[id.to_s] ||= 0
        @calls[id.to_s] += 1
        ret = nil
        @timers[id.to_s].add! { ret = yield }
        ret
      end

      def print_times(reset = false)
        @timers.each do |id, timer|
          puts "#{timer.label}: #{timer.real.round 2}s total, #{(timer.real / @calls[id]).round 2}s/call"
        end
        @timers = {} if reset
        @calls = {} if reset
      end
    end
  end
end

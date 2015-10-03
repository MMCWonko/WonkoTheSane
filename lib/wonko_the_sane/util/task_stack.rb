class TaskStack
  class << self; attr_accessor :queue; end
  self.queue = []
  def self.push(task)
    self.queue.push task
  end
  def self.push_defered(task)
    self.queue.unshift task
  end
  def self.pop
    task = self.queue.pop
    task.call
  end
  def self.pop_all
    self.pop until self.queue.empty?
  end
  def self.in_background(&block)
    thread = Thread.new &block
    TaskStack.pop_all
    thread.join.value
  end
end

class Rule
  attr_accessor :action

  def initialize(action)
    @action = action
  end

  def to_json
    { action: @action }
  end

  def self.allowed_on_side(rules, side)
    allowed = :allow
    rules.map { |r| r.is_a?(Rule) ? r : Rule.from_json(r) }.each do |rule|
      if rule.is_a? ImplicitRule
        allowed = rule.action
      elsif rule.is_a? SidedRule
        allowed = rule.action if rule.side == side
      end
    end
    allowed == :allow
  end

  def self.from_json(obj)
    if obj.key? :os
      return OsRule.new obj[:action].to_sym, obj[:os][:name], obj[:os][:version], obj[:os][:arch]
    elsif obj.key? :side
      return SidedRule.new obj[:action].to_sym, obj[:side].to_sym
    else
      return ImplicitRule.new obj[:action].to_sym
    end
  end
end
class ImplicitRule < Rule
end
class OsRule < Rule
  attr_accessor :os
  attr_accessor :os_version
  attr_accessor :os_arch

  def initialize(action, os, os_version = nil, os_arch = nil)
    super(action)
    @os = os
    @os_version = os_version
    @os_arch = os_arch
  end

  def to_json
    obj = super
    obj[:os] = { name: @os }
    obj[:os][:version] = @os_version if @os_version
    obj[:os][:arch] = @os_arch if @os_arch
    return obj
  end
end
class SidedRule < Rule
  attr_accessor :side

  def initialize(action, side)
    super(action)
    @side = side
  end

  def to_json
    obj = super
    obj[:side] = @side
    return obj
  end
end

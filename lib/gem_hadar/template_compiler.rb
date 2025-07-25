require 'erb'

class GemHadar::TemplateCompiler
  include Tins::BlockSelf
  include Tins::MethodMissingDelegator::DelegatorModule

  def initialize(&block)
    super block_self(&block)
    @values = {}
    instance_eval(&block)
  end

  def compile(src, dst)
    template = File.read(src)
    File.open(dst, 'w') do |output|
      erb = ERB.new(template, nil, '-')
      erb.filename = src.to_s
      output.write erb.result binding
    end
  end

  def method_missing(id, *a, &b)
    if a.empty? && id && @values.key?(id)
      @values[id]
    elsif a.size == 1
      @values[id] = a.first
    else
      super
    end
  end
end

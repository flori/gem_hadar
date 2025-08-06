require 'erb'

class GemHadar::TemplateCompiler
  include Tins::BlockSelf
  include Tins::MethodMissingDelegator::DelegatorModule

  # The initialize method sets up the template compiler instance by evaluating
  # the provided block in the context of the object.
  #
  # @param block [ Proc ] the block to be evaluated for configuring the template compiler
  def initialize(&block)
    super block_self(&block)
    @values = {}
    instance_eval(&block)
  end

  # The compile method processes an ERB template file and writes the rendered
  # output to a destination file.
  #
  # This method reads the content of a source file, treats it as an ERB
  # template, and renders it using the provided binding.
  # The result is then written to a specified destination file, effectively
  # generating a new file based on the template.
  #
  # @param src [ String ] the path to the source ERB template file
  # @param dst [ String ] the path to the destination file where the rendered content will be written
  def compile(src, dst)
    template = File.read(src)
    File.open(dst, 'w') do |output|
      erb = ERB.new(template, nil, '-')
      erb.filename = src.to_s
      output.write erb.result binding
    end
  end

  # The method_missing method handles dynamic attribute access and assignment.
  #
  # This method intercepts calls to undefined methods on the object, allowing
  # for dynamic retrieval and setting of values through method calls. If a
  # method name corresponds to a key in @values and no arguments are provided,
  # it returns the stored value. If a single argument is provided, it stores
  # the argument under the method name as a key in @values. For all other
  # cases, it delegates the call to the superclass implementation.
  #
  # @param id [ Symbol ] the name of the method being called
  # @param a [ Array ] the arguments passed to the method
  # @param b [ Proc ] the block passed to the method
  #
  # @return [ Object ] the value associated with the method name if retrieving,
  #                    otherwise delegates to super
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

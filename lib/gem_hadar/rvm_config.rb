class GemHadar
  # A class that encapsulates Ruby Version Manager (RVM) configuration settings
  # for a gem project.
  #
  # This class is responsible for managing RVM-specific configuration such as
  # the Ruby version to use and the gemset name. It provides a structured way
  # to define and access these settings within the context of a GemHadar
  # configuration.
  #
  # @example Configuring RVM settings
  #   GemHadar do
  #     rvm do
  #       use '3.0.0'
  #       gemset 'my_gem_dev'
  #     end
  #   end
  class RvmConfig
    extend DSLKit::DSLAccessor
    include DSLKit::BlockSelf

    # The initialize method sets up the RvmConfig instance by evaluating the
    # provided block in the context of the object.
    #
    # @param block [ Proc ] the block to be evaluated for configuring the RVM settings
    #
    # @return [ GemHadar::RvmConfig ] the initialized RvmConfig instance
    def initialize(&block)
      @outer_scope = block_self(&block)
      instance_eval(&block)
    end

    # The use method retrieves or sets the Ruby version to be used with RVM.
    #
    # This method serves as an accessor for the Ruby version configuration
    # within the RVM (Ruby Version Manager) settings. When called without
    # arguments, it returns the configured Ruby version. When called with
    # an argument, it sets the Ruby version to be used.
    #
    # @return [ String ] the Ruby version string configured for RVM use
    # @see GemHadar::RvmConfig
    dsl_accessor :use do `rvm tools strings`.split(/\n/).full?(:last) || 'ruby' end

    # The gemset method retrieves or sets the RVM gemset name for the project.
    #
    # This method serves as an accessor for the RVM (Ruby Version Manager)
    # gemset configuration within the nested RvmConfig class. When called
    # without arguments,
    # it returns the configured gemset name, which defaults to the gem's name.
    # When called with an argument, it sets the gemset name to be used with RVM.
    #
    # @return [ String ] the RVM gemset name configured for the project
    # @see GemHadar::RvmConfig#use
    # @see GemHadar::RvmConfig
    dsl_accessor :gemset do @outer_scope.name end
  end
end

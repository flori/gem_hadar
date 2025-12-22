# A class that encapsulates changelog configuration settings for a gem project.
#
# This class provides a structured way to define and manage settings related to
# changelog generation within the GemHadar framework. It allows configuration
# of the changelog filename and the commit message used when adding entries.
#
# @example Configuring changelog settings
#   GemHadar do
#     changelog do
#       filename 'CHANGELOG.md'
#       commit_message 'Update changelog'
#     end
#   end
class GemHadar::ChangelogConfig
  extend DSLKit::DSLAccessor

  # This method creates a new instance of the ChangelogConfig class and then
  # evaluates the provided block in the context of the new instance to
  # configure the changelog settings.
  #
  # @param block [Proc] the block to be evaluated for configuring the changelog
  #   settings
  #
  # @return [GemHadar::ChangelogConfig] the initialized ChangelogConfig
  #   instance
  def initialize(&block)
    instance_eval(&block)
  end

  # The filename attribute accessor for configuring the changelog filename.
  #
  # This method sets up a DSL accessor for the filename attribute, which specifies
  # the name of the changelog file to be used when generating or modifying
  # changelog entries. It provides a way to define the location of the changelog
  # file that will be processed during various changelog operations within the
  # gem project.
  #
  # @return [ String, nil ] the name of the changelog file or nil if not set
  dsl_accessor :filename

  # The commit_message method retrieves or sets the Git commit message used
  # when adding changelog entries.
  #
  # This method serves as an accessor for the commit_message attribute within
  # the ChangelogConfig class. When called without arguments, it returns the
  # configured commit message, which defaults to 'Add to changes'. When called
  # with an argument, it sets the commit message to be used for Git operations
  # related to changelog management.
  #
  # @return [ String ] the default commit message 'Add to changes' when no custom message is set
  dsl_accessor :commit_message, 'Add to changes'
end

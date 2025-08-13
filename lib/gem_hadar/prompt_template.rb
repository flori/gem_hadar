# A module that provides default prompt templates for interacting with AI models
# when generating GitHub release changelogs and semantic version bump suggestions.
#
# This module contains methods that return system prompts and template strings
# used by the GemHadar framework to instruct AI models on how to format
# responses for release notes and versioning decisions. These prompts are
# designed to produce structured, relevant output that aligns with
# development workflow requirements.
module GemHadar::PromptTemplate
  # The default_git_release_system_prompt method returns the system prompt used
  # for generating GitHub release changelogs.
  #
  # This prompt instructs the AI model to act as a Ruby programmer who creates
  # markdown-formatted changelog entries for new releases. The generated
  # content helps users understand what has changed in the software.
  #
  # @return [ String ] the system prompt for GitHub release changelog generation
  def default_git_release_system_prompt
    <<~EOT
      You are a Ruby programmer generating changelog messages in markdown
      format for new releases, so users can see what has changed. Remember you
      are not a chatbot of any kind.
    EOT
  end

  # The default_git_release_prompt method returns the prompt used for
  # generating GitHub release changelogs.
  #
  # This prompt instructs the AI model to create a markdown-formatted changelog
  # entry for a new release. It specifies guidelines for what constitutes
  # significant changes, emphasizing the exclusion of trivial updates
  # and the inclusion of only verified and impactful modifications.
  #
  # @return [ String ] the prompt template for GitHub release changelog generation
  def default_git_release_prompt
    <<~EOT
      Output the content of a changelog for the new release of %{name} %{version}

      **Strictly** follow these guidelines:

        - Use bullet points in markdown format (`-`) to list significant changes.
        - Exclude trivial updates such as:
          * Version number increments
          * Dependency version bumps (unless they resolve critical issues)
          * Minor code style adjustments
          * Internal documentation tweaks
        - Include only verified and substantial changes that impact
          functionality, performance, or user experience.
        - If unsure about a change's significance, omit it from the output.
        - Avoid adding any comments or notes; keep the output purely factual.

      These are the log messages including patches for the new release:

      %{log_diff}
    EOT
  end

  # The default_version_bump_system_prompt method returns the system prompt
  # used for generating semantic version bump suggestions.
  #
  # This prompt instructs the AI model to act as an expert in semantic versioning,
  # analyzing provided changes and determining whether a major, minor, or build
  # version bump is appropriate. It requires the model to provide a brief
  # explanation of its reasoning followed by a single line containing only one
  # word: 'major', 'minor', or 'build'.
  #
  # @return [ String ] the system prompt for semantic version bump suggestion generation
  def default_version_bump_system_prompt
    <<~EOT
      You are an expert at semantic versioning. Analyze the provided changes
      and suggest whether to bump major, minor, or build version according to
      Semantic Versioning. Provide a brief explanation of your reasoning,
      followed by a single line containing only one word: 'major', 'minor', or
      'build'.
    EOT
  end

  # The default_version_bump_prompt method returns the prompt template used for
  # generating semantic version bump suggestions.
  #
  # This prompt instructs the AI model to analyze provided changes and
  # determine whether a major, minor, or build version bump is appropriate
  # according to Semantic Versioning principles. It requires the model to first
  # provide a brief explanation of its reasoning, followed by a single line
  # containing only one word: 'major', 'minor', or 'build'.
  #
  # @return [ String ] the prompt template for semantic version bump suggestion generation
  def default_version_bump_prompt
    <<~EOT
      Given the current version %{version} and the following changes:

      %{log_diff}

      Please explain your reasoning for suggesting a version bump and then end
      with a single line containing only one word: 'major', 'minor', or
      'build'.
    EOT
  end
end

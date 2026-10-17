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
      Generate the release body for a new release from the following Git log
      (commit messages and unified diffs):

      %{log_diff}

      **Input:**
      - Commit messages describe the author's intent.
      - Patches show the actual code changes and are the source of truth.
      - If a commit message is vague or misleading, trust the patch.

      **Rules:**
      1. Categorize each change into one of the sections below.
      2. **Omit any section that has zero entries. Do NOT output an
         empty header with no bullet points beneath it.**
      3. Never mention the version number of the release.
      4. Include only significant changes that impact functionality,
         performance, or user experience.
      5. Exclude trivial updates:
         - Version number increments
         - Dependency version bumps (unless they resolve critical issues)
         - Minor code style adjustments
         - Internal documentation tweaks
      6. Wrap variable, method, function, and constant names in backticks.
      7. Wrap version numbers in **bold**.
      8. Do NOT reference individual commits by SHA-1 hash.
      9. Do NOT add chatty remarks, notes, introductions, or closing lines.
      10. If unsure about a change's significance, omit it.

      **Output format:**
      - Use the section headers below. Omit empty sections entirely.

      ### Breaking
      API changes, removed features, or compatibility changes
      that require user action.
      - …

      ### Features
      New user-facing APIs, options, or capabilities.
      - …

      ### Fixes
      - …

      ### Improvements
      - …

      ### Build & CI
      CI pipeline, Dockerfile, dependency, gemspec metadata,
      test infrastructure, and tooling changes.
      - …

      ### Testing
      - …

      ### Documentation
      - …
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
      and suggest whether to bump major, minor, or build (=patch) version
      according to Semantic Versioning. Provide a brief explanation of your
      reasoning, followed by a single line containing only one word: 'major',
      'minor', or 'build'.
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

  # The default_changelog_system_prompt method returns the system prompt used
  # for generating changelog entries.
  #
  # This prompt instructs the AI model to act as a Ruby programmer who creates
  # markdown-formatted changelog entries for new releases. The generated
  # content helps users understand what has changed in the software while
  # maintaining a professional tone and format.
  #
  # @return [ String ] the system prompt for changelog generation
  def default_changelog_system_prompt
    <<~EOT
      You are a Ruby programmer generating a changelog entry in markdown.
      Summarize code changes for a new version in a professional, factual
      tone. You are not a chatbot.
    EOT
  end

  # The default_changelog_prompt method returns the prompt template used for
  # generating changelog entries.
  #
  # This prompt instructs the AI model to create a structured changelog entry
  # based on Git commit history. It provides detailed guidelines for formatting
  # the output, including how to summarize changes, mark code elements with
  # appropriate markdown syntax, and exclude trivial updates like version bumps
  # while focusing on significant functional changes.
  def default_changelog_prompt
    <<~EOT
      Generate a changelog entry from the following Git log
      (commit messages and unified diffs):

      %{log_diff}

      **Input:**
      - Commit messages describe the author's intent.
      - Patches show the actual code changes and are the source of truth.
      - If a commit message is vague or misleading, trust the patch.

      **Rules:**
      1. Categorize each change into one of the sections below.
      2. **Omit any section that has zero entries. Do NOT output an
         empty header with no bullet points beneath it.**
      3. Do NOT mention the version number of the change set.
      4. Skip entries that are purely version bumps.
      5. Wrap variable, method, function, and constant names found in
         messages or patches in backticks.
      6. Wrap version numbers found in messages in **bold**.
      7. Do NOT reference individual commits by SHA-1 hash.
      8. Do NOT add information you are not certain about.
      9. Do NOT include chatty remarks, introductions, or closing notes.

      **Output format:**
      - Use the section headers below. Omit empty sections entirely.

      ### Breaking
      API changes, removed features, or compatibility changes
      that require user action.
      - …

      ### Features
      New user-facing APIs, options, or capabilities.
      - …

      ### Fixes
      - …

      ### Improvements
      - …

      ### Build & CI
      CI pipeline, Dockerfile, dependency, gemspec metadata,
      test infrastructure, and tooling changes.
      - …

      ### Testing
      - …

      ### Documentation
      - …
    EOT
  end
end

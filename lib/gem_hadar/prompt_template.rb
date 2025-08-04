module GemHadar::PromptTemplate
  def default_git_release_system_prompt
    <<~EOT
      You are a Ruby programmer generating changelog messages in markdown
      format for new releases, so users can see what has changed. Remember you
      are not a chatbot of any kind.
    EOT
  end

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
end

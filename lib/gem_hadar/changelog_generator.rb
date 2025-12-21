require 'json'
require 'tempfile'

class GemHadar
  # A class that generates changelog entries by analyzing Git history and AI
  # processing
  #
  # The ChangelogGenerator class provides functionality to create structured
  # changelog entries based on Git commit history. It can generate individual
  # changelog entries for specific version ranges or create complete changelogs
  # including all version entries. The class integrates with AI models to
  # produce human-readable changelog content by processing Git logs through
  # configured prompts and models.
  #
  # @example Generating a changelog entry for a version range
  #   generator = GemHadar::ChangelogGenerator.new
  #   entry = generator.generate('v1.0.0', 'v1.2.0')
  #
  # @example Generating a complete changelog
  #   generator = GemHadar::ChangelogGenerator.new
  #   generator.generate_full(STDOUT)
  #
  # @example Adding changelog entries to an existing file
  #   GemHadar::ChangelogGenerator.add_to_file('CHANGELOG.md')
  class ChangelogGenerator
    include GemHadar::Utils
    include GemHadar::PromptTemplate

    def initialize(gem_hadar)
      @gem_hadar = gem_hadar
    end

    # The generate method creates a changelog entry by analyzing Git history
    # and AI processing.
    #
    # This method retrieves the Git log for a specified range of commits,
    # processes the log through an AI model using configured prompts, and
    # formats the result into a markdown changelog entry with a date header.
    #
    # @param from [ String ] the starting version or commit reference for the
    #   Git log range
    # @param to [ String ] the ending version or commit reference for the Git
    #   log range, defaults to 'HEAD'
    #
    # @return [ String ] a formatted markdown changelog entry including date
    #   and AI-generated content
    # @return [ String ] a minimal changelog entry with just date and version
    #   when no changes are found
    def generate(from, to = 'HEAD')
      from = GemHadar::VersionSpec[from]
      to   = GemHadar::VersionSpec[to]

      range = "#{from.tag}..#{to.tag}"

      log = `git log #{range}`
      $?.success? or raise "Failed to get git log for range #{range}"

      date = `git log -n1 --pretty='format:%cd' --date=short #{to.tag.inspect}`.chomp

      if log.strip.empty?
        return "\n## #{date} #{to.without_prefix.to_s}\n"
      end

      system          = xdg_config('gem_hadar', 'changelog_system_prompt.txt', default_changelog_system_prompt)
      prompt_template = xdg_config('gem_hadar', 'changelog_prompt.txt', default_changelog_prompt)
      prompt = prompt_template % { log_diff: log }

      response = ollama_generate(system:, prompt:)

      changes = response.gsub(/\t/, '  ')

      return "\n## #{date} #{to.tag}\n\n#{changes}\n"
    end

    # The generate_range method creates a changelog for a specific version
    # range by processing Git log differences and AI-generated content
    #
    # This method retrieves version tags within a specified range, filters them
    # based on the provided version boundaries, generates changelog entries
    # for each version in the range, and writes the complete changelog to the
    # provided output stream
    #
    # @param output [ IO ] the output stream to which the changelog will be
    #   written
    # @param from [ String ] the starting version or commit reference for the
    #   range
    # @param to [ String ] the ending version or commit reference for the
    #   range, defaults to 'HEAD'
    def generate_range(output, from, to)
      from = GemHadar::VersionSpec[from]
      to   = GemHadar::VersionSpec[to]

      versions = read_versions

      unless versions.any?
        raise "No version tags found in repository"
      end

      versions = versions.select do |v|
        v >= from && v <= to
      end

      changelog = generate_changelog(versions)

      output << changelog.join("")
    end

    # The generate_full method creates a complete changelog by processing all
    # version tags in the repository and generating entries for each
    # consecutive pair of versions
    #
    # This method retrieves all semantic version tags from the Git repository,
    # sorts them, and generates changelog entries for each pair of consecutive
    # versions. It also adds an initial entry for the first version with a
    # "Start" marker
    #
    # @param output [ IO ] the output stream to which the complete changelog
    #   will be written
    #
    # @return [ String ] a complete changelog including all version entries and
    #   a header
    #
    # @raise [ RuntimeError ] if no version tags are found in the repository
    def generate_full(output)
      versions = read_versions

      unless versions.any?
        raise "No version tags found in repository"
      end

      first_version = versions.first
      date          = `git log -n1 --pretty='format:%cd' --date=short #{first_version.tag.to_s}`.chomp
      changelog     = ["\n## #{date} #{first_version.tag.to_s}\n\n* Start\n"]

      changelog = generate_changelog(versions, changelog:)

      changelog.unshift "# Changes\n"

      output << changelog.join("")
    end

    # The add_to_file method appends new changelog entries to an existing
    # changelog file
    #
    # This method identifies the highest version already present in the
    # changelog file, retrieves all subsequent version tags from the Git
    # repository, and generates changelog entries for each consecutive pair of
    # versions. It then inserts these entries into the file after the existing
    # content, maintaining the chronological order of changes.
    #
    # @param filename [ String ] the path to the changelog file to which
    #   entries will be added
    def add_to_file(filename)
      highest_version = find_highest_version(filename)

      if highest_version
        versions = read_versions
        versions = versions.drop_while { |t| t < highest_version }
      else
        raise ArgumentError, "Could not find highest version in #{filename.inspect}"
      end

      return if versions.size < 2

      changelog = generate_changelog(versions)
      return if changelog.empty?
      inject_into_filename(filename, changelog)
    end

    # The changelog_exist? method checks whether a changelog file exists in the
    # project.
    #
    # This method verifies the presence of a changelog file by checking if the
    # file path determined by changelog_filename exists in the filesystem.
    #
    # @return [ TrueClass, FalseClass ] true if the changelog file exists,
    #   false otherwise
    def changelog_exist?
      changelog_filename.exist?
    end

    # The changelog_version_added? method checks whether a specific version has
    # already been added to the changelog file.
    #
    # This method verifies if a given version is present in the changelog file
    # by examining each line for a match with the version tag.
    #
    # @param version [ String ] the version to check for in the changelog
    #
    # @return [ TrueClass, FalseClass ] true if the version is found in the
    #   changelog, false otherwise
    #
    # @raise [ ArgumentError ] if the changelog file does not exist
    def changelog_version_added?(version)
      version = GemHadar::VersionSpec[version]
      changelog_exist? or
        raise ArgumentError, "Changelog #{changelog_filename.to_s} doesn't exist!"
      File.new(changelog_filename).any? do |line|
        line =~ /#{version.tag}/ and return true
      end
      false
    end

    private

    # The changelog_filename method returns the Pathname object for the
    # changelog file path.
    #
    # This method accesses the changelog_filename attribute from the associated
    # GemHadar instance and wraps it in a Pathname object for convenient file
    # path manipulation.
    #
    # @return [ Pathname ] the Pathname object representing the changelog file path
    def changelog_filename
      Pathname.new(@gem_hadar.changelog_filename)
    end

    # The ollama_generate method delegates AI generation requests to the
    # associated GemHadar instance.
    #
    # This method acts as a proxy that forwards the provided options to the
    # ollama_generate method of the parent GemHadar object, enabling AI-powered
    # text generation using configured Ollama models.
    #
    # @param opts [ Hash ] the options to pass to the AI generation method
    #
    # @return [ String, nil ] the generated response from the AI model or nil
    #   if generation fails
    def ollama_generate(**opts)
      @gem_hadar.ollama_generate(**opts)
    end

    # The read_versions method retrieves and processes semantic version tags
    # from the Git repository.
    #
    # This method fetches all Git tags from the repository, filters them to
    # include only those that match semantic versioning patterns (containing
    # three numeric components separated by dots), removes any 'v' prefix from
    # the tags, and sorts the resulting version specifications
    # in ascending order according to semantic versioning rules.
    #
    # @return [ Array<GemHadar::VersionSpec> ] an array of VersionSpec objects
    #   representing the semantic versions found in the repository, sorted in
    #   ascending order
    def read_versions
      tags = `git tag`.lines.grep(/^v?\d+\.\d+\.\d+$/).map(&:chomp)

      versions = tags.map { |tag| GemHadar::VersionSpec[tag] }
      versions = versions.sort_by(&:version)
    end

    # The generate_changelog method creates a series of changelog entries by
    # processing consecutive version pairs.
    #
    # This method takes an array of version specifications, iterates through
    # them in pairs, and generates AI-powered changelog entries for each range.
    # It uses the ollama_generate method to produce content for each version
    # interval and collects the results in reverse order.
    #
    # @param versions [ Array<GemHadar::VersionSpec> ] an array of version
    #   specifications to process
    #
    # @return [ Array<String> ] an array of changelog entry strings in reverse
    #   chronological order
    def generate_changelog(versions, changelog: [])
      versions = versions.each_cons(2).
        with_infobar(total: versions.size - 1, label: 'Change')
      versions.each do |range_from, range_to|
        changelog << generate(range_from, range_to)
        +infobar
      end
      changelog.reverse
    end

    # The inject_into_filename method inserts changelog entries into a
    # specified file.
    #
    # This method reads an existing file line by line and identifies the
    # location of a "# Changes" header. When this header is found, it inserts
    # the provided changelog entries immediately after the header
    # and before the next empty line.
    #
    # @param filename [ String ] the path to the file into which changelog
    #   entries will be injected
    # @param changelog [ Array<String> ] an array of changelog entry strings to
    #   be inserted into the file
    #
    # @see GemHadar::ChangelogGenerator#add_to_file
    def inject_into_filename(filename, changelog)
      File.open(filename) do |input|
        File.secure_write(filename) do |output|
          start_add = nil
          input.each do |line|
            if start_add.nil? && line =~ /^# Changes$/
              start_add = true
              output.puts line
              next
            end
            if start_add && line =~ /^$/
              changelog.each do |entry|
                output.puts entry
              end
              output.puts line
              start_add = false
              next
            end
            output.puts line
          end
        end
      end
    end

    # The find_highest_version method extracts version specifications from
    # a changelog file and returns the highest version found
    #
    # This method reads through the specified file line by line, scanning for
    # lines that match the pattern of a changelog entry header with a version
    # number, and collects all found version specifications. It then determines
    # and returns the version specification with
    # the highest version number
    #
    # @param filename [ String ] the path to the changelog file to process
    #
    # @return [ GemHadar::VersionSpec, nil ] the highest version specification
    #   found in the file, or nil if no versions are found
    def find_highest_version(filename)
      File.open(filename, ?r) do |input|
        specs = []
        input.each do |line|
          line.scan(/^## \d{4}-\d{2}-\d{2} v(\d+\.\d+\.\d+)$/) do
            specs << GemHadar::VersionSpec[$1]
          end
        end
        specs.max_by(&:version)
      end
    end
  end
end

require 'term/ansicolor'
require 'tins/xt/secure_write'
require 'fileutils'
require 'pathname'

class GemHadar
end
require 'gem_hadar/warn'

# A module that provides SimpleCov-related functionality for code coverage
# analysis.
#
# This module encapsulates the setup and configuration of SimpleCov for Ruby
# projects, including initialization, formatter selection, and warning message
# handling. It integrates with the GemHadar framework to provide detailed
# coverage reporting capabilities while maintaining consistent output
# formatting and error handling.
#
# @example Initializing SimpleCov with GemHadar GemHadar::SimpleCov.start
module GemHadar::SimpleCov

  # A formatter class that generates detailed JSON coverage reports from
  # SimpleCov results.
  #
  # This class is responsible for processing code coverage data produced by
  # SimpleCov and transforming it into a structured JSON format that includes
  # both line and branch coverage statistics for individual files, as well as
  # overall project coverage metrics. It calculates various percentages and
  # counts, then writes the complete coverage data to a dedicated JSON file in
  # the coverage directory.
  #
  # @example Using the ContextFormatter to generate coverage reports
  #   formatter = GemHadar::SimpleCov::ContextFormatter.new
  #   formatter.format(simplecov_result)
  class ContextFormatter
    include FileUtils

    # The format method processes code coverage results and generates a
    # detailed JSON report.
    #
    # This method takes a SimpleCov result object and transforms its coverage
    # data into a structured format that includes both line and branch coverage
    # statistics for individual files, as well as overall project coverage
    # metrics. It calculates various percentages and counts, then writes the
    # complete coverage data to a JSON file in the coverage directory.
    #
    # @param result [ SimpleCov::Result ] the coverage result object containing files and statistics
    #
    # @return [ String ] an empty string, as the method's primary purpose is to write data to a file
    def format(result)
      files = result.files.map do |file|
        line_coverage_statistics = extract_coverage_info(file.coverage_statistics[:line])
        branch_coverage_statistics = extract_coverage_info(file.coverage_statistics[:branch])
        {
          filename: file.filename,
          line_coverage_statistics:,
          branch_coverage_statistics:,
        }
      end
      covered_files = result.files.count { |file| file.coverage_statistics[:line].covered > 0 }
      uncovered_files = result.files.count { |file| file.coverage_statistics[:line].covered == 0 }
      files_count = result.files.length
      files_covered_percent = files_count > 0 ? (100 * covered_files.to_f / files_count).round(2) : 0
      branch_covered_percent =
        result.total_branches > 0 ? (result.covered_branches.to_f / result.total_branches * 100).round(2) : 0
      coverage_data = {
        project_name:,
        version:,
        timestamp: Time.now.iso8601,
        files:,
        overall_coverage: {
          covered_percent: result.covered_percent.round(2),
          total_lines: result.total_lines,
          covered_lines: result.covered_lines,
          missed_lines: result.missed_lines,
          branch_covered_percent:,
          total_branches: result.total_branches,
          covered_branches: result.covered_branches,
          missed_branches: result.missed_branches,
          coverage_strength: result.covered_strength.round(2),
          least_covered_file: (result.least_covered_file rescue nil),
          covered_files:,
          uncovered_files:,
          files_count:,
          files_covered_percent:,
        },
      }

      # Write to a dedicated coverage data file,
      coverage_dir = Pathname.new('coverage')
      mkdir_p coverage_dir
      filename = File.expand_path(coverage_dir + 'coverage_context.json')
      File.secure_write(filename, JSON.pretty_generate(coverage_data))
      STDERR.puts "Wrote detailed coverage context to #{filename.to_s.inspect}."
      ""
    end

    private

    include GemHadar::Warn

    # The project_name method retrieves the name of the current working
    # directory.
    #
    # This method obtains the absolute path of the current working directory
    # and extracts its basename, returning it as a string. It is typically used
    # to identify the project name based on the directory structure.
    #
    # @return [ String ] the name of the current working directory
    def project_name
      Pathname.pwd.basename.to_s # I hope…
    end

    # The version method reads and returns the current version string from the
    # VERSION file.
    #
    # This method attempts to read the contents of the VERSION file, removing
    # any trailing whitespace. If the VERSION file does not exist, it returns
    # the string 'unknown' instead.
    #
    # @return [ String ] the version string read from the VERSION file, or
    # 'unknown' if the file is missing
    def version
      File.read('VERSION').chomp
    rescue Errno::ENOENT => e
      warn "Using version 'unknown', caught #{e.class}: #{e}"
      'unknown'
    end

    # The extract_coverage_info method transforms coverage statistics into a
    # structured hash format.
    #
    # This method takes a coverage statistics object and extracts specific
    # attributes into a new hash, making the data more accessible for reporting
    # and analysis.
    #
    # @param coverage_statistics [ SimpleCov::CoverageStatistics ] the coverage
    # statistics object to process
    #
    # @return [ Hash ] a hash containing the extracted coverage metrics with
    # keys :total, :covered, :missed, :strength, and :percent
    def extract_coverage_info(coverage_statistics)
      %i[ total covered missed strength percent ].each_with_object({}) do |attr, hash|
        hash[attr] = coverage_statistics.send(attr)
      end
    end
  end

  class << self
    include Term::ANSIColor

    # The default_block method returns a lambda that configures SimpleCov with
    # branch coverage and multiple formatters.
    #
    # This method constructs a default configuration block for SimpleCov that
    # enables branch coverage, adds a filter based on the caller's directory,
    # and sets up a multi-formatter including SimpleFormatter, HTMLFormatter,
    # and a custom ContextFormatter.
    #
    # @return [ Proc ] a lambda configuring SimpleCov with coverage settings
    # and formatters
    def default_block
      filter = "#{File.basename(File.dirname(caller.first))}/"
      -> {
        enable_coverage :branch
        add_filter filter
        formatter SimpleCov::Formatter::MultiFormatter.new([
          SimpleCov::Formatter::SimpleFormatter,
          SimpleCov::Formatter::HTMLFormatter,
          GemHadar::SimpleCov::ContextFormatter,
        ])
      }
    end

    # The start method initializes and configures SimpleCov for code coverage
    # analysis.
    #
    # This method sets up SimpleCov with optional profile and block
    # configuration, but only if the START_SIMPLECOV environment variable is
    # set to 1. It handles the case where SimpleCov is not available by
    # displaying a warning and installation instructions.
    #
    # @param profile [ String, nil ] the SimpleCov profile to use for
    # configuration
    # @param block [ Proc, nil ] optional block containing custom configuration
    def start(profile = nil, &block)
      if ENV['START_SIMPLECOV'].to_i != 1
        STDERR.puts color(226) {
          "Skip starting Simplecov for code coverage, "\
          "enable by setting env var: START_SIMPLECOV=1"
        }
        return
      end
      require 'simplecov'
      STDERR.puts color(76) { "Configuring Simplecov for code coverage." }
      block ||= default_block
      SimpleCov.start(profile, &block)
    rescue LoadError => e
      warn "Caught #{e.class}: #{e}"
      STDERR.puts "Install with: gem install simplecov"
    end

    private

    include GemHadar::Warn
  end
end

# A class that represents a version specification for a gem.
#
# This class provides functionality to parse and manipulate version strings,
# including handling of semantic versioning formats and optional 'v' prefixes.
# It supports creating version specifications from various input formats and
# provides methods to access the underlying version information and string
# representation.
#
# @example Creating a version specification
#   version_spec = GemHadar::VersionSpec['1.2.3']
#
# @example Checking if a version is a HEAD reference
#   version_spec = GemHadar::VersionSpec['HEAD']
#   version_spec.head? # => true
#
# @example Getting the version tag with appropriate prefixing
#   version_spec = GemHadar::VersionSpec['1.2.3']
#   version_spec.tag # => 'v1.2.3'
#
# @example Comparing versions
#   version1 = GemHadar::VersionSpec['1.2.3']
#   version2 = GemHadar::VersionSpec['1.2.4']
#   version1.version < version2.version # => true
class GemHadar::VersionSpec
  class << self
    # The [] method creates a new VersionSpec instance from a specification.
    #
    # This factory method attempts to extract version information from the
    # provided specification, handling both gem specifications and version
    # strings. It supports optional prefix handling for the resulting version
    # string.
    #
    # @param spec [Object] the specification to parse, typically a String or Gem::Specification
    #
    # @param with_prefix [Boolean] if true, ensures the version string has a 'v' prefix
    #
    # @param without_prefix [Boolean] if true, ensures the version string does not have a 'v' prefix
    #
    # @return [GemHadar::VersionSpec] a new VersionSpec instance
    #
    # @raise [ArgumentError] if both with_prefix and without_prefix are specified simultaneously
    def [](spec, with_prefix: nil, without_prefix: nil)
      !(with_prefix && without_prefix) or
        raise ArgumentError, 'with_prefix and without_prefix is invalid'
      spec.is_a?(self) and return spec
      obj, version = nil, (spec.version rescue nil)
      if version
        ;
      elsif /\Av?(\d+\.\d+\.\d+)\z/ =~ spec
        begin
          version = Tins::StringVersion::Version.new($1)
        rescue ArgumentError
        end
      end
      spec = spec.to_s
      if version
        if with_prefix
          spec = spec.sub(/\A(?!v)/, 'v')
        elsif without_prefix
          spec = spec.sub(/\Av?/, '')
        end
      end
      obj = new(spec, version)
      obj.freeze
    end

    private_class_method :new
  end

  # Initializes a new VersionSpec instance.
  #
  # @param string [String] the original string representation of the version
  # @param version [Tins::StringVersion::Version, nil] the parsed version object or nil if parsing failed
  def initialize(string, version)
    @string, @version = string, version
  end

  # Retrieves the parsed version object.
  #
  # @return [Tins::StringVersion::Version, nil] the parsed version object or nil if parsing failed
  attr_reader :version

  # Checks if a version object was successfully parsed.
  #
  # @return [Boolean] true if version was parsed successfully, false otherwise
  def version?
    !!@version
  end

  # The head? method checks if the version string represents a HEAD reference.
  #
  # This method returns true if the internal string representation of the version
  # spec is exactly 'HEAD', indicating that it refers to the latest commit
  # rather than a specific tagged version.
  #
  # @return [ Boolean ] true if the version string is 'HEAD', false otherwise
  def head?
    @string == 'HEAD'
  end

  # The tag method returns the version tag string with appropriate prefixing.
  #
  # This method checks if the version represents a HEAD reference and returns
  # the raw string representation if so. Otherwise, it returns the version
  # string with a 'v' prefix added to it.
  #
  # @return [ String ] the version tag string, either as-is for HEAD or with 'v' prefix added
  def tag
    head? ? to_s : with_prefix
  end

  # The untag method returns the version string without a 'v' prefix.
  #
  # This method checks if the version represents a HEAD reference and returns
  # the raw string representation if so. Otherwise, it returns the version
  # string with the 'v' prefix removed.
  #
  # @return [ String ] the version string without 'v' prefix or the raw string
  #                    if it represents a HEAD reference
  def untag
    head? ? to_s : without_prefix
  end

  # Returns the original string representation.
  #
  # @return [String] the original version string
  def to_s
    @string.to_s
  end

  # Removes the 'v' prefix from the version string if present.
  #
  # @return [String] the version string without 'v' prefix
  def without_prefix
    to_s.sub(/\Av/, '')
  end

  # Adds a 'v' prefix to the version string if not already present.
  #
  # @return [String] the version string with 'v' prefix
  def with_prefix
    to_s.sub(/\A(?!v)/, 'v')
  end
end

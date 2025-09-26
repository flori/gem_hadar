require 'net/http'
require 'json'

module GemHadar::GitHub
end

# A client for creating GitHub releases via the GitHub API.
#
# This class provides functionality to interact with the GitHub Releases API,
# enabling the creation of new releases for a specified repository. It handles
# the HTTP request setup, including appropriate headers and authentication,
# and processes the API response to either return the created release data or
# raise an error if the creation fails.
#
# @example Creating a release
#   creator = GemHadar::GitHub::ReleaseCreator.new(
#     owner: 'myorg',
#     repo: 'myrepo',
#     token: 'ghp_mytoken'
#   )
#   release_data = creator.perform(
#     tag_name: 'v1.0.0',
#     target_commitish: 'main',
#     body: 'Release notes here',
#     name: 'Version 1.0.0'
#   )
class GemHadar::GitHub::ReleaseCreator
  class << self
    attr_accessor :github_api_url
  end
  self.github_api_url = 'https://api.github.com'

  # The initialize method sets up the ReleaseCreator instance with required
  # GitHub API configuration.
  #
  # This method stores the owner, repository, and authentication token needed
  # to interact with the GitHub Releases API. It also accepts an optional API
  # version parameter to specify which version of the GitHub API to use.
  #
  # @param owner [ String ] the GitHub username or organization name
  # @param repo [ String ] the repository name
  # @param token [ String ] the personal access token for authentication
  # @param api_version [ String ] the GitHub API version to use (defaults to '2022-11-28')
  def initialize(owner:, repo:, token:, api_version: '2022-11-28')
    @owner       = owner
    @repo        = repo
    @token       = token
    @api_version = api_version
  end

  # The perform method creates a new GitHub release using the GitHub API.
  #
  # This method sends a POST request to the GitHub Releases API to create a new
  # release for the specified repository. It constructs the appropriate HTTP
  # headers including authentication and content type, prepares the release
  # data with the provided parameters, and handles the API response by parsing
  # successful responses or raising an error for failed requests.
  #
  # @param tag_name [ String ] the name of the tag to associate with the release
  # @param target_commitish [ String ] the commit SHA or branch name to use for the release
  # @param body [ String ] the release notes or description content
  # @param name [ String ] the name of the release (defaults to tag_name)
  # @param draft [ Boolean ] whether to create a draft release (defaults to false)
  # @param prerelease [ Boolean ] whether to mark the release as a pre-release (defaults to false)
  #
  # @return [ JSON::GenericObject ] the parsed response data from the GitHub API containing
  #   details about the created release
  #
  # @raise [ RuntimeError ] if the GitHub API request fails with a non-success status code
  def perform(tag_name:, target_commitish:, body:, name: tag_name, draft: false, prerelease: false)
    uri = URI("#{self.class.github_api_url}/repos/#@owner/#@repo/releases")

    headers = {
      "Accept"               => "application/vnd.github+json",
      "Authorization"        => "Bearer #@token",
      "Content-Type"         => "application/json",
      "X-GitHub-Api-Version" => @api_version,
      "User-Agent"           => [ GemHadar.name, GemHadar::VERSION ] * ?/,
    }

    data = {
      tag_name:,
      target_commitish:,
      body:,
      name:,
      draft:,
      prerelease:,
    }.compact

    response = Net::HTTP.post(uri, JSON(data), headers)
    case response
    when Net::HTTPSuccess
      JSON.parse(response.body, object_class: JSON::GenericObject)
    else
      error_data =
        begin
          JSON.pretty_generate(JSON.parse(response.body))
        rescue
          response.body
        end
      raise "Failed to create release. Status: #{response.code}\n\n#{error_data}"
    end
  end
end

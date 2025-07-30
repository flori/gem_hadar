require 'net/http'
require 'json'

module GemHadar::GitHub
end

class GemHadar::GitHub::ReleaseCreator
  class << self
    attr_accessor :github_api_url
  end
  self.github_api_url = 'https://api.github.com'

  def initialize(owner:, repo:, token:, api_version: '2022-11-28')
    @owner       = owner
    @repo        = repo
    @token       = token
    @api_version = api_version
  end

  def perform(tag_name:, target_commitish:, body:, name: tag_name, draft: false, prerelease: false)
    uri = URI("#{self.class.github_api_url}/repos/#{@owner}/#{@repo}/releases")

    headers = {
      "Accept" => "application/vnd.github+json",
      "Authorization" => "Bearer #{@token}",
      "X-GitHub-Api-Version" => @api_version
    }

    data = {
      tag_name:,
      target_commitish:,
      body:,
      name:,
      draft:,
      prerelease:,
    }.compact

    req = Net::HTTP::Post.new(uri.request_uri, headers)
    req.body = JSON(data)

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
      http.request(req)
    end

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
      error_msg = "Failed to create release. Status: #{response.code}\n\n#{error_data}"
      raise error_msg
    end
  rescue => e
    warn "Error creating release: #{e.message}"
    nil
  end
end

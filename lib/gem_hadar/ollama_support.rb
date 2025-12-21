require 'ollama'

# A module that provides Ollama AI integration support for GemHadar.
#
# This module includes methods for initializing an Ollama client, retrieving
# the configured AI model name, and fetching model options for AI generation.
# It also provides a method to generate responses
# from Ollama AI models using the configured settings.
module GemHadar::OllamaSupport
  # The ollama method initializes and returns an Ollama client instance.
  #
  # This method constructs an Ollama client by first determining the base URL
  # from the OLLAMA_URL environment variable, falling back to the OLLAMA_HOST
  # environment variable with a default value of 'localhost:11434'. It then
  # creates a client configuration hash including read and connect timeouts
  # before instantiating and returning a new Ollama::Client object.
  #
  # @return [ Ollama::Client ] a configured Ollama client instance ready for use
  def ollama
    base_url      = ENV['OLLAMA_URL'] || "http://%s" % ENV.fetch('OLLAMA_HOST', 'localhost:11434')
    client_config = {
      base_url:        base_url,
      read_timeout:    600,
      connect_timeout: 60
    }
    Ollama::Client.new(**client_config)
  end
  memoize method: :ollama

  # The ollama_model method retrieves the name of the Ollama AI model to be
  # used for generating responses.
  #
  # It first checks the OLLAMA_MODEL environment variable for a custom model
  # specification. If the environment variable is not set, it falls back to
  # using the default model name, which is determined by the
  # ollama_model_default dsl method.
  #
  # @return [ String ] the name of the Ollama AI model to be used
  def ollama_model
    ENV.fetch('OLLAMA_MODEL', ollama_model_default)
  end

  alias model ollama_model

  # The options method retrieves and configures the Ollama model options for AI
  # generation.
  #
  # This method fetches the JSON configuration for the Ollama model from the
  # OLLAMA_MODEL_OPTIONS environment variable, or uses an empty JSON object if
  # the variable is not set. It then merges default values for temperature,
  # top_p, and min_p parameters to ensure consistent AI response
  # characteristics.
  #
  # @return [ Hash ] a hash containing the merged Ollama model options
  #   including default values for temperature, top_p, and min_p
  def options
    options = JSON(ENV.fetch('OLLAMA_MODEL_OPTIONS', '{}'))
    options.merge!("temperature" => 0, "top_p" => 1, "min_p" => 0.1)
  end
  memoize method: :options

  # Generates a response from an AI model using the Ollama::Client.
  #
  # @param [String] system The system prompt for the AI model.
  # @param [String] prompt The user prompt to generate a response to.
  # @return [String, nil] The generated response or nil if generation fails.
  def ollama_generate(system:, prompt:)
    ollama.generate(
      model:, system:, prompt:, options:, stream: false, think: false
    ).response
  end
end

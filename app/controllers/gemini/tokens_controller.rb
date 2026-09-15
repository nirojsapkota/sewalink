class Gemini::TokensController < ApplicationController
  before_action :authenticate_user!

  def create
    api_key = ENV['GEMINI_API_KEY'] || Rails.application.credentials.gemini_api_key || Rails.application.credentials.dig(:gemini, :api_key)

    if api_key.blank?
      return render json: { error: "GEMINI_API_KEY is not configured" }, status: :internal_server_error
    end

    # NOTE: Google's ephemeral-token provisioning endpoint moved from
    # v1alpha `authTokens:create` (query-param key auth) to v1beta
    # `auth_tokens` (header-based `x-goog-api-key` auth). The old
    # endpoint now 404s. The token itself is still only valid against
    # the v1alpha `BidiGenerateContentConstrained` WebSocket endpoint
    # (see real_time_chat_controller.js), so only the provisioning
    # call below changes.
    uri = URI("https://generativelanguage.googleapis.com/v1beta/auth_tokens")

    payload = {
      uses: 1,
      expireTime: (Time.now.utc + 30.minutes).iso8601
    }

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.request_uri, {
      'Content-Type' => 'application/json',
      'x-goog-api-key' => api_key
    })
    request.body = payload.to_json

    Rails.logger.info "[GeminiTokens] Requesting ephemeral token for live voice session"
    
    response = http.request(request)
    
    # Prepare tools for the frontend
    camel_tools = Gemini::ToolDefinitions::ALL_TOOLS.map do |tool|
      {
        name: tool[:name],
        description: tool[:description],
        parameters: {
          type: tool[:parameters][:type],
          properties: tool[:parameters][:properties],
          required: tool[:parameters][:required]
        }
      }
    end

    if response.code == '200'
      token_data = JSON.parse(response.body)
      Rails.logger.info "[GeminiTokens] Success: #{token_data['name']}"
      render json: {
        token: token_data['name'],
        tools: camel_tools
      }
    else
      Rails.logger.error "[GeminiTokens] Error: #{response.code} - #{response.body}"
      render json: { error: "Unable to start voice chat right now. Please try again shortly." }, status: :service_unavailable
    end
  end
end

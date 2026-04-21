class Gemini::TokensController < ApplicationController
  before_action :authenticate_user!

  def create
    api_key = ENV['GEMINI_API_KEY'] || Rails.application.credentials.gemini_api_key || Rails.application.credentials.dig(:gemini, :api_key)

    if api_key.blank?
      return render json: { error: "GEMINI_API_KEY is not configured" }, status: :internal_server_error
    end

    uri = URI("https://generativelanguage.googleapis.com/v1alpha/authTokens:create?key=#{api_key}")
    
    payload = {
      config: {
        model: "models/gemini-3.1-flash-live-preview",
        uses: 1,
        expireTime: (Time.now.utc + 30.minutes).iso8601
      }
    }

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    request = Net::HTTP::Post.new(uri.request_uri, { 'Content-Type' => 'application/json' })
    request.body = payload.to_json

    Rails.logger.info "[GeminiTokens] Requesting token for model: #{payload[:config][:model]}"
    
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
      # Fallback to direct key if token creation fails
      render json: {
        api_key: api_key,
        tools: camel_tools
      }
    end
  end
end

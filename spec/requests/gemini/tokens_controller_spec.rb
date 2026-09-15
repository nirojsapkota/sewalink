require 'rails_helper'

RSpec.describe "Gemini::Tokens", type: :request do
  let(:user) { create(:user) }

  before do
    sign_in user
    allow(Rails.application.credentials).to receive(:gemini_api_key).and_return("test-api-key")
  end

  describe "POST /gemini/tokens" do
    it "requests an ephemeral token from the current v1beta auth_tokens endpoint" do
      stub_request(:post, "https://generativelanguage.googleapis.com/v1beta/auth_tokens")
        .with(headers: { "X-Goog-Api-Key" => "test-api-key" })
        .to_return(status: 200, body: { name: "auth_tokens/abc123" }.to_json, headers: { "Content-Type" => "application/json" })

      post "/gemini/tokens", params: { token: {} }

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["token"]).to eq("auth_tokens/abc123")
      expect(body["tools"]).to be_an(Array)
    end

    it "returns a friendly error when Google's provisioning call fails" do
      stub_request(:post, "https://generativelanguage.googleapis.com/v1beta/auth_tokens")
        .to_return(status: 404, body: "")

      post "/gemini/tokens", params: { token: {} }

      expect(response).to have_http_status(:service_unavailable)
      expect(response.parsed_body["error"]).to be_present
    end
  end
end

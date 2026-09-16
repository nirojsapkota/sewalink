require 'rails_helper'

RSpec.describe "Gemini::Tools", type: :request do
  let(:user) { create(:user) }

  before { sign_in user }

  describe "POST /gemini/tools/execute — search_knowledge_base" do
    it "rejects the call when the query has no trigger keyword, without calling Bedrock" do
      expect(Bedrock::KnowledgeBaseClient).not_to receive(:retrieve_and_generate)

      post "/gemini/tools/execute", params: {
        name: "search_knowledge_base",
        args: { query: "What is the weather today?" },
        call_id: "call-1"
      }

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["result"]).to eq("error")
      expect(body["message"]).to match(/help.*faq.*guide.*policy/i)
    end

    it "calls Bedrock and returns the answer when the query includes a trigger keyword" do
      allow(Bedrock::KnowledgeBaseClient).to receive(:retrieve_and_generate)
        .with("Can you help me understand how escrow works?")
        .and_return(answer: "Escrow holds payment until work is confirmed complete.", citations: ["s3://bucket/05_payments_escrow_commission.md"])

      post "/gemini/tools/execute", params: {
        name: "search_knowledge_base",
        args: { query: "Can you help me understand how escrow works?" },
        call_id: "call-2"
      }

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["result"]).to eq("success")
      expect(body["answer"]).to eq("Escrow holds payment until work is confirmed complete.")
      expect(body["sources"]).to eq(["s3://bucket/05_payments_escrow_commission.md"])
    end

    it "returns an error when Bedrock finds no answer" do
      allow(Bedrock::KnowledgeBaseClient).to receive(:retrieve_and_generate).and_return(answer: nil, citations: [])

      post "/gemini/tools/execute", params: {
        name: "search_knowledge_base",
        args: { query: "Can you help me with something totally unrelated?" },
        call_id: "call-3"
      }

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["result"]).to eq("error")
    end
  end
end

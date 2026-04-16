require 'rails_helper'

RSpec.describe TaskDraftGeneratorService, type: :service do
  let(:audio_file_path) { Rails.root.join("spec", "fixtures", "files", "sample.mp3").to_s }
  let(:service) { described_class.new(audio_file_path) }
  let(:category) { Category.create!(name_en: "Plumbing", name_ne: "प्लम्बिङ") }
  let(:openai_client_double) { instance_double(OpenAI::Client) }
  let(:audio_double) { double('Audio') }
  let(:chat_double) { double('Chat') }

  before do
    allow(OpenAI::Client).to receive(:new).and_return(openai_client_double)
    allow(openai_client_double).to receive(:audio).and_return(audio_double)
    allow(openai_client_double).to receive(:chat).and_return(chat_double)
    
    # Ensure at least one category exists
    category
  end

  describe '#call' do
    context 'when file validation fails' do
      it 'returns error if file does not exist' do
        service = described_class.new("nonexistent.mp3")
        result = service.call
        expect(result[:success]).to eq(false)
        expect(result[:error]).to eq("File not found")
      end

      it 'returns error if file is too large' do
        allow(File).to receive(:size).and_return(11.megabytes)
        result = service.call
        expect(result[:success]).to eq(false)
        expect(result[:error]).to eq("File too large (max 10MB)")
      end

      it 'returns error if file type is invalid' do
        invalid_file = Rails.root.join("spec", "fixtures", "files", "sample.txt").to_s
        File.write(invalid_file, "dummy")
        service = described_class.new(invalid_file)
        result = service.call
        expect(result[:success]).to eq(false)
        expect(result[:error]).to eq("Invalid file type")
        File.delete(invalid_file)
      end
    end

    context 'when OpenAI APIs succeed' do
      let(:transcription_response) { { "text" => "I need a plumber to fix a pipe for 500 rupees" } }
      let(:chat_response_content) do
        {
          "title" => "Fix a pipe",
          "description" => "I need a plumber to fix a pipe",
          "budget" => 500,
          "category_id" => category.id
        }.to_json
      end
      let(:chat_response) do
        {
          "choices" => [
            {
              "message" => {
                "content" => chat_response_content
              }
            }
          ]
        }
      end

      before do
        allow(audio_double).to receive(:transcribe).and_return(transcription_response)
        allow(chat_double).to receive(:parameters).and_return(chat_response) # This might not be right for ruby-openai 8.3.0
      end

      it 'returns a structured hash with extracted details' do
        # ruby-openai chat usage is client.chat(parameters: { ... })
        allow(openai_client_double).to receive(:chat).and_return(chat_response)
        
        result = service.call

        expect(result).to be_a(Hash)
        expect(result[:success]).to eq(true)
        expect(result[:data]).to be_a(Hash)
        expect(result[:data][:title]).to eq("Fix a pipe")
        expect(result[:data][:description]).to eq("I need a plumber to fix a pipe")
        expect(result[:data][:budget]).to eq(500)
        expect(result[:data][:category_id]).to eq(category.id)
      end
    end

    context 'when OpenAI API returns an error' do
      before do
        allow(audio_double).to receive(:transcribe).and_raise(Faraday::Error.new("API error"))
      end

      it 'handles errors gracefully' do
        result = service.call

        expect(result).to be_a(Hash)
        expect(result[:success]).to eq(false)
        expect(result[:error]).to include("API error")
      end
    end
  end
end

require 'faye/websocket'
require 'eventmachine'
require 'json'

module Gemini
  class LiveService
    def initialize(on_message: nil)
      @api_key = ENV['GEMINI_API_KEY']
      @on_message = on_message
      @url = "wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1alpha.GenerativeService.BidiGenerateContent?key=#{@api_key}"
      @ws = nil
    end

    def connect
      @thread = Thread.new do
        EM.run do
          @ws = Faye::WebSocket::Client.new(@url)

          @ws.on :open do |event|
            Rails.logger.info "[Gemini::LiveService] Connected to Gemini Multimodal Live API"
            send_setup
          end

          @ws.on :message do |event|
            begin
              data = JSON.parse(event.data)
              @on_message&.call(data)
            rescue => e
              Rails.logger.error "[Gemini::LiveService] Error parsing message: #{e.message}"
            end
          end

          @ws.on :close do |event|
            Rails.logger.info "[Gemini::LiveService] Connection closed: #{event.code} #{event.reason}"
            EM.stop
          end

          @ws.on :error do |event|
            Rails.logger.error "[Gemini::LiveService] WebSocket Error: #{event.message}"
          end
        end
      end
    end

    def send_audio(base64_pcm)
      return unless @ws && @ws.ready_state == Faye::WebSocket::API::OPEN
      
      payload = {
        real_time_input: {
          media_chunks: [
            {
              mime_type: "audio/pcm;rate=16000",
              data: base64_pcm
            }
          ]
        }
      }
      
      EM.next_tick { @ws.send(payload.to_json) }
    end

    def close
      @ws&.close
      EM.stop if EM.reactor_running?
    end

    private

    def send_setup
      setup_msg = {
        setup: {
          model: "models/gemini-2.0-flash-exp",
          generation_config: {
            response_modalities: ["AUDIO"]
          },
          tools: [ { function_declarations: Gemini::ToolDefinitions::ALL_TOOLS } ],
          system_instruction: {
            parts: [ { text: "You are sewaLink's AI assistant. Help users create service tasks. Ask for title, description, budget, and location if missing." } ]
          }
        }
      }
      @ws.send(setup_msg.to_json)
    end
  end
end

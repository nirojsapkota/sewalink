require 'faye/websocket'
require 'eventmachine'
require 'json'

module Gemini
  class LiveService
    def initialize(user: nil, on_message: nil)
      @api_key = ENV['GEMINI_API_KEY'] || Rails.application.credentials.gemini_api_key || Rails.application.credentials.dig(:gemini, :api_key)
      @user = user
      @on_message = on_message
      @url = "wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent?key=#{@api_key}"
      @ws = nil
      @setup_complete = false
      @obj_id = self.object_id
    end

    def connect
      return if @ws
      puts "[Gemini:#{@obj_id}] Connecting..."
      @thread = Thread.new do
        begin
          if EM.reactor_running?
            setup_websocket
          else
            EM.run { setup_websocket }
          end
        rescue => e
          puts "[Gemini:#{@obj_id}] EM ERROR: #{e.message}"
        end
      end
    end

    def send_audio(base64_pcm)
      return unless @ws && @ws.ready_state == 1 && @setup_complete
      
      payload = {
        realtimeInput: {
          mediaChunks: [
            {
              mimeType: "audio/l16;rate=16000",
              data: base64_pcm
            }
          ]
        }
      }
      EM.next_tick { @ws.send(payload.to_json) }
    end

    def close
      puts "[Gemini:#{@obj_id}] Closing..."
      @ws&.close
      @ws = nil
    end

    private

    def setup_websocket
      @ws = Faye::WebSocket::Client.new(@url)

      @ws.on :open do |event|
        puts "[Gemini:#{@obj_id}] WebSocket OPEN"
        send_setup
      end

      @ws.on :message do |event|
        begin
          data = JSON.parse(event.data)
          puts "[Gemini:#{@obj_id}] RECEIVED FROM GOOGLE: #{data.keys}"
          
          if data['setupComplete']
            @setup_complete = true
            puts "[Gemini:#{@obj_id}] Setup Handshake Complete. AI is ready to listen."
          end
          handle_message(data)
          @on_message&.call(data)
        rescue => e
          puts "[Gemini:#{@obj_id}] Parse Error: #{e.message}"
        end
      end

      @ws.on :close do |event|
        puts "[Gemini:#{@obj_id}] WebSocket CLOSED: #{event.code} #{event.reason}"
        @ws = nil
        @setup_complete = false
      end
    end

    def handle_message(data)
      if data['toolCall']
        data['toolCall']['functionCalls'].each { |call| execute_tool(call) }
      end
    end

    def execute_tool(call)
      case call['name']
      when 'create_task_draft'
        args = call['args']
        puts "[Gemini:#{@obj_id}] Updating Task: #{args}"
        
        task = @user.tasks.draft.last || @user.tasks.new(status: :draft)
        task.title = args['title'] if args['title'].present?
        task.description = args['description'] if args['description'].present?
        task.budget = args['budget'] if args['budget'].present?
        task.location = args['location'] if args['location'].present?
        task.category ||= Category.first

        if task.save
          Turbo::StreamsChannel.broadcast_replace_to(
            @user, :live_chat,
            target: "ai_task_preview",
            partial: "live_chats/task_preview",
            locals: { task: task }
          )

          response_msg = {
            toolResponse: {
              functionResponses: [
                {
                  id: call["id"],
                  name: call["name"],
                  response: { result: "success", task_id: task.id }
                }
              ]
            }
          }
          EM.next_tick { @ws.send(response_msg.to_json) }
        end
      end
    end

    def send_setup
      setup_msg = {
        setup: {
          model: "models/gemini-2.5-flash-native-audio-latest",
          generationConfig: {
            responseModalities: ["AUDIO", "TEXT"]
          },
          tools: [ { functionDeclarations: Gemini::ToolDefinitions::ALL_TOOLS } ],
          systemInstruction: {
            parts: [ { text: "You are a helpful assistant. You MUST respond to every user input immediately with voice." } ]
          }
        }
      }
      @ws.send(setup_msg.to_json)
    end
  end
end

require 'faye/websocket'
require 'eventmachine'
require 'json'

module Gemini
  class LiveService
    def initialize(user: nil, on_message: nil)
      @api_key = ENV['GEMINI_API_KEY']
      @user = user
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
              handle_message(data)
              @on_message&.call(data)
            rescue => e
              Rails.logger.error "[Gemini::LiveService] Error parsing message: #{e.message} - #{e.backtrace.first}"
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

    def handle_message(data)
      if data['tool_call']
        data['tool_call']['function_calls'].each do |call|
          execute_tool(call)
        end
      end
    end

    def execute_tool(call)
      case call['name']
      when 'create_task_draft'
        args = call['args']
        title = args['title']
        description = args['description']
        budget = args['budget']
        location = args['location']

        task = @user.tasks.draft.last || @user.tasks.new(status: :draft)
        task.title = title if title.present?
        task.description = description if description.present?
        task.budget = budget if budget.present?
        task.location = location if location.present?
        task.category ||= Category.first # Fallback

        if task.save
          # Broadcast Turbo Stream
          Turbo::StreamsChannel.broadcast_replace_to(
            @user,
            :live_chat,
            target: "ai_task_preview",
            partial: "live_chats/task_preview",
            locals: { task: task }
          )

          # Send tool response
          response_msg = {
            tool_response: {
              function_responses: [
                {
                  id: call["id"],
                  name: call["name"],
                  response: { result: "success", task_id: task.id }
                }
              ]
            }
          }
          EM.next_tick { @ws.send(response_msg.to_json) }
        else
          Rails.logger.error "[Gemini::LiveService] Failed to save task: #{task.errors.full_messages}"
        end
      end
    end

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

require 'faye/websocket'
require 'eventmachine'
require 'json'

module Gemini
  class LiveService
    def initialize(user: nil, on_message: nil)
      @api_key = ENV['GEMINI_API_KEY'] || Rails.application.credentials.gemini_api_key || Rails.application.credentials.dig(:gemini, :api_key)
      @user = user
      @on_message = on_message
      @url = "wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1alpha.GenerativeService.BidiGenerateContent?key=#{@api_key}"
      @ws = nil
      @setup_complete = false
      @obj_id = self.object_id
    end

    def connect
      return if @ws
      puts "[Gemini:#{@obj_id}] Connecting to v1alpha..."

      Thread.new { EM.run } unless EM.reactor_running?
      sleep 0.1 until EM.reactor_running?

      EM.next_tick { setup_websocket }

      30.times do
        break if @ws
        sleep 0.1
      end
    end

    def send_audio(base64_pcm)
      return unless @ws && @ws.ready_state == 1 && @setup_complete

      payload = {
        realtime_input: {
          media_chunks: [{
            mime_type: "audio/pcm;rate=16000",
            data: base64_pcm
          }]
        }
      }
      EM.next_tick { @ws.send(payload.to_json) }
    end

    def send_turn_complete
      return unless @ws && @ws.ready_state == 1

      payload = {
        client_content: {
          turns: [{ role: "user", parts: [{ text: "" }] }],
          turn_complete: true
        }
      }

      puts "[Gemini:#{@obj_id}] End of turn signaled."
      EM.next_tick { @ws.send(payload.to_json) }
    end

    def close
      puts "[Gemini:#{@obj_id}] Closing..."
      EM.next_tick { @ws&.close }
      @ws = nil
      @setup_complete = false
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
          if data['setupComplete']
            @setup_complete = true
            puts "[Gemini:#{@obj_id}] Setup Complete. Triggering greeting..."
            # Send an empty text prompt to make the AI speak its intro
            send_text_prompt("")
          end

          handle_message(data)
          @on_message&.call(data)
        rescue => e
          puts "[Gemini:#{@obj_id}] Message error: #{e.message}"
        end
      end

      @ws.on :close do |event|
        puts "[Gemini:#{@obj_id}] WebSocket CLOSED: #{event.code} #{event.reason}"
        @ws = nil
        @setup_complete = false
      end

      @ws.on :error do |event|
        puts "[Gemini:#{@obj_id}] WebSocket ERROR: #{event.message}"
      end
    end

    def send_text_prompt(text)
      return unless @ws && @ws.ready_state == 1

      payload = {
        client_content: {
          turns: [{ role: "user", parts: [{ text: text }] }],
          turn_complete: true
        }
      }
      EM.next_tick { @ws.send(payload.to_json) }
    end

    def handle_message(data)
      # Support both camelCase (v1beta) and snake_case (v1alpha)
      tool_call = data['toolCall'] || data['tool_call']
      if tool_call
        calls = tool_call['functionCalls'] || tool_call['function_calls']
        calls&.each { |call| execute_tool(call) }
      end

      server_content = data['serverContent'] || data['server_content']
      if server_content
        model_turn = server_content['modelTurn'] || server_content['model_turn']
        puts "[Gemini:#{@obj_id}] AI Turn Received" if model_turn
      end
    end

    def execute_tool(call)
      name = call['name']
      args = call['args']
      puts "[Gemini:#{@obj_id}] Tool Call: #{name}(#{args})"

      case name
      when 'create_task_draft'
        task = @user.tasks.draft.last || @user.tasks.new(status: :draft)
        task.title = args['title'] if args['title'].present?
        task.description = args['description'] if args['description'].present?
        task.budget = args['budget'] if args['budget'].present?
        task.location = args['location'] if args['location'].present?
        task.category ||= Category.first

        if task.save
          puts "[Gemini:#{@obj_id}] Task Saved: ID #{task.id}"
          Turbo::StreamsChannel.broadcast_replace_to(
            @user, :live_chat,
            target: "ai_task_preview",
            partial: "live_chats/task_preview",
            locals: { task: task }
          )

          response_payload = {
            tool_response: {
              function_responses: [{
                id: call["id"],
                name: call["name"],
                response: { result: "success", task_id: task.id }
              }]
            }
          }
          EM.next_tick { @ws.send(response_payload.to_json) }
        end
      end
    end

    def send_setup
      puts "[Gemini:#{@obj_id}] Sending Setup Frame..."

      user_name = @user&.name.present? ? @user.name.split.first : "there"
      greeting_instruction = "Your first response MUST be a vocal greeting, such as 'Hello, #{user_name}! How can I help you?'. After that, your primary goal is to help the user create a service task by calling the 'create_task_draft' tool as soon as you have details like title, description, budget, or location."

      setup_msg = {
        setup: {
          model: "models/gemini-2.5-flash-native-audio-latest",
          generation_config: {
            response_modalities: ["AUDIO"]
          },
          tools: [{ function_declarations: Gemini::ToolDefinitions::ALL_TOOLS }],
          system_instruction: {
            parts: [ { text: greeting_instruction } ]
          }
        }
      }
      @ws.send(setup_msg.to_json)
    end
  end
end

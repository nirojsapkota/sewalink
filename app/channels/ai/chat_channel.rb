module AI
  class ChatChannel < ApplicationCable::Channel
    def subscribed
      @service = Gemini::LiveService.new(
        user: current_user,
        on_message: method(:handle_gemini_message)
      )
      @service.connect
      stream_from "ai_chat_#{current_user&.id || 'guest'}"
    end

    def unsubscribed
      @service&.close
    end

    def send_audio(data)
      @service&.send_audio(data['audio'])
    end

    private

    def handle_gemini_message(data)
      # Forward the message from Gemini back to the browser
      transmit(data)
    end
  end
end

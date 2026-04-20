class AiChatChannel < ApplicationCable::Channel
  def subscribed
    puts "[AiChatChannel] User #{current_user&.id} subscribed. Initializing Gemini..."
    @service = Gemini::LiveService.new(
      user: current_user,
      on_message: method(:handle_gemini_message)
    )
    @service.connect
    stream_from "ai_chat_#{current_user&.id || 'guest'}"
  end

  def unsubscribed
    puts "[AiChatChannel] User #{current_user&.id} unsubscribed."
    @service&.close
  end

  def send_audio(data)
    # Forward the audio to the existing service instance
    @service&.send_audio(data['audio'])
  end

  def send_turn_complete
    puts "[AiChatChannel] Received turn_complete signal."
    @service&.send_turn_complete
  end

  private

  def handle_gemini_message(data)
    puts "[AiChatChannel] Transmitting Gemini message to browser: #{data.keys}"
    transmit(data)
  end
end

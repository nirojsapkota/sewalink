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
    # Log that we are receiving audio from the browser
    puts "[AiChatChannel] -> Forwarding audio to Gemini (#{data['audio'].length} bytes)"
    @service&.send_audio(data['audio'])
  end

  def send_turn_complete
    puts "[AiChatChannel] -> Received silence. Signalling end of turn."
    @service&.send_turn_complete
  end

  private

  def handle_gemini_message(data)
    puts "[AiChatChannel] <- Transmitting Gemini response: #{data.keys}"
    transmit(data)
  end
end

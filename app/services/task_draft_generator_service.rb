class TaskDraftGeneratorService
  def initialize(audio_file_path, history: [])
    @audio_file_path = audio_file_path
    @history = history
  end

  def call
    return { success: false, error: "File not found" } unless File.exist?(@audio_file_path)
    return { success: false, error: "File too large (max 10MB)" } if File.size(@audio_file_path) > 10.megabytes
    
    allowed_extensions = %w[.mp3 .mp4 .mpeg .mpga .m4a .wav .webm]
    return { success: false, error: "Invalid file type" } unless allowed_extensions.include?(File.extname(@audio_file_path).downcase)

    client = OpenAI::Client.new

    # Step 1: Transcribe the audio
    transcription_response = client.audio.transcribe(
      parameters: {
        model: "whisper-1",
        file: File.open(@audio_file_path, "rb")
      }
    )
    
    transcript = transcription_response["text"]
    @history << { role: "user", content: transcript }

    # Step 2: Extract structured data using GPT with history
    categories = Category.all.pluck(:id, :name_en).map { |id, name| { id: id, name: name } }
    
    prompt = <<~PROMPT
      You are an assistant that extracts task details from a conversational transcript.
      The user is describing a task they need done. They might provide information across multiple turns.
      
      Extract the following information:
      - title: A short, descriptive title for the task (string or null)
      - description: A detailed description based on the transcript (string or null)
      - budget: The budget mentioned (integer or null).
      - category_id: Infer the best matching category from the list and provide its ID (integer or null).
      - next_question: If any of the above fields are missing or unclear, provide a polite question in the user's likely language (English or Nepali) to ask for that specific detail. If everything is clear, leave as null.
      
      Available Categories:
      #{categories.to_json}
      
      Respond STRICTLY in JSON format with keys: "title", "description", "budget", "category_id", "next_question".
    PROMPT

    messages = [
      { role: "system", content: prompt }
    ] + @history.last(10) # Keep last 10 messages for context

    chat_response = client.chat(
      parameters: {
        model: "gpt-4o-mini",
        response_format: { type: "json_object" },
        messages: messages
      }
    )

    parsed_content = JSON.parse(chat_response.dig("choices", 0, "message", "content"))
    
    # Add assistant response to history
    @history << { role: "assistant", content: chat_response.dig("choices", 0, "message", "content") }

    {
      success: true,
      history: @history,
      data: {
        title: parsed_content["title"],
        description: parsed_content["description"],
        budget: parsed_content["budget"]&.to_i,
        category_id: parsed_content["category_id"],
        next_question: parsed_content["next_question"]
      }
    }
  rescue StandardError => e
    {
      success: false,
      error: e.message
    }
  end
end

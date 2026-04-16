class TaskDraftGeneratorService
  def initialize(audio_file_path)
    @audio_file_path = audio_file_path
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

    # Step 2: Extract structured data using GPT
    categories = Category.all.pluck(:id, :name_en).map { |id, name| { id: id, name: name } }
    
    prompt = <<~PROMPT
      You are an assistant that extracts task details from a transcript.
      The transcript is a user describing a task they need done.
      
      Extract the following information:
      - title: A short, descriptive title for the task (string)
      - description: A detailed description based on the transcript (string)
      - budget: The budget mentioned in the transcript (integer). If no budget is mentioned, leave as null.
      - category_id: Infer the best matching category from the following list and provide its ID.
      
      Available Categories:
      #{categories.to_json}
      
      Respond STRICTLY in JSON format with the keys: "title", "description", "budget", "category_id".
    PROMPT

    chat_response = client.chat(
      parameters: {
        model: "gpt-4o-mini",
        response_format: { type: "json_object" },
        messages: [
          { role: "system", content: prompt },
          { role: "user", content: transcript }
        ]
      }
    )

    parsed_content = JSON.parse(chat_response.dig("choices", 0, "message", "content"))

    {
      success: true,
      data: {
        title: parsed_content["title"],
        description: parsed_content["description"],
        budget: parsed_content["budget"]&.to_i,
        category_id: parsed_content["category_id"]
      }
    }
  rescue StandardError => e
    {
      success: false,
      error: e.message
    }
  end
end

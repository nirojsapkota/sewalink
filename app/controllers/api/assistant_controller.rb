module Api
  class AssistantController < ApplicationController
    before_action :authenticate_user!

    def create
      audio_file = params[:audio]

      if audio_file.blank?
        return render json: { error: 'No audio file provided' }, status: :unprocessable_entity
      end

      # Create a tempfile to pass to the service
      tempfile = Tempfile.new(['voice_assistant', File.extname(audio_file.original_filename)])
      begin
        tempfile.binmode
        tempfile.write(audio_file.read)
        tempfile.rewind

        # Reuse Whisper for transcription
        client = OpenAI::Client.new
        transcription_response = client.audio.transcribe(
          parameters: {
            model: "whisper-1",
            file: File.open(tempfile.path, "rb")
          }
        )
        
        transcript = transcription_response["text"]

        # Interpret intent using GPT
        categories = Category.all.pluck(:id, :name_en)
        
        prompt = <<~PROMPT
          You are a helpful assistant for "sewaLink", a task marketplace in Nepal.
          The user is giving a voice command. You need to determine their intent and provide a structured response.
          
          Intents:
          1. search_tasks: User wants to find work (e.g., "Find me plumbing jobs").
             - Return: { "action": "redirect", "url": "/tasks?category_id=ID&location=LOC", "message": "Showing plumbing jobs near you." }
          2. post_task: User wants to hire someone (e.g., "I need a cleaner").
             - Return: { "action": "redirect", "url": "/tasks/new", "message": "Let's post a new task for a cleaner." }
          3. view_dashboard: User wants to see their tasks or bids.
             - Return: { "action": "redirect", "url": "/poster_dashboard", "message": "Opening your dashboard." }
          4. unknown: Command not recognized.
             - Return: { "action": "notify", "message": "I'm sorry, I didn't quite catch that. Try asking to find jobs or post a task." }

          Available Category IDs:
          #{categories.to_json}

          Respond STRICTLY in JSON format with keys: "action", "url" (optional), "message".
          The "message" should be in the user's likely language (Nepali or English).
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

        result = JSON.parse(chat_response.dig("choices", 0, "message", "content"))
        render json: result, status: :ok

      ensure
        tempfile.close
        tempfile.unlink
      end
    end
  end
end

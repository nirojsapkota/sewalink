module Api
  class VoiceTasksController < ApplicationController
    before_action :authenticate_user!
    before_action :check_audio_size, only: [:create]

    def create
      audio_file = params[:audio]

      if audio_file.blank?
        return render json: { error: 'No audio file provided' }, status: :unprocessable_entity
      end

      # Create a tempfile to pass to the service
      tempfile = Tempfile.new(['voice_task', File.extname(audio_file.original_filename)])
      begin
        tempfile.binmode
        tempfile.write(audio_file.read)
        tempfile.rewind

        result = TaskDraftGeneratorService.new(tempfile.path).call

        if result[:success]
          render json: result[:data], status: :ok
        else
          render json: { error: result[:error] }, status: :unprocessable_entity
        end
      ensure
        tempfile.close
        tempfile.unlink
      end
    end

    private

    def check_audio_size
      if request.content_length > 10.megabytes
        render json: { error: 'Audio file too large (max 10MB)' }, status: :payload_too_large
      end
    end
  end
end

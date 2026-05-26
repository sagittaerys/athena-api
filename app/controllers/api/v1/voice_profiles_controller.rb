module Api
  module V1
    class VoiceProfilesController < ApplicationController
      def show
        voice_profile = current_user.voice_profiles.find_by(id: params[:id])

        if voice_profile
          render json: { voice_profile: serialize(voice_profile) }, status: :ok
        else
          render json: { error: "Not found" }, status: :not_found
        end
      end

      def create
        unless params[:audio_file].present?
          render json: { error: "Audio file is required" }, status: :unprocessable_entity
          return
        end

        voice_profile = current_user.voice_profiles.build(status: "pending")

        unless voice_profile.save
          render json: { error: voice_profile.errors.full_messages.join(", ") },
                 status: :unprocessable_entity
          return
        end

        audio_path = save_audio_file(params[:audio_file], voice_profile.id)

        begin
          result = TtsService.clone_voice(audio_path)

          voice_profile.update!(
            kokoro_profile_id: result["voice_profile_id"],
            sample_url: audio_path,
            status: "ready"
          )

          render json: { voice_profile: serialize(voice_profile) }, status: :created

        rescue => e
          voice_profile.update!(status: "failed")
          Rails.logger.error "Voice cloning failed: #{e.message}"
          render json: { error: "Voice cloning failed" }, status: :internal_server_error
        end
      end

      def destroy
        voice_profile = current_user.voice_profiles.find_by(id: params[:id])

        if voice_profile
          voice_profile.destroy
          render json: { message: "Voice profile deleted" }, status: :ok
        else
          render json: { error: "Not found" }, status: :not_found
        end
      end

      private

      def save_audio_file(file, voice_profile_id)
        dir = Rails.root.join("storage", "voice_samples", voice_profile_id.to_s)
        FileUtils.mkdir_p(dir)
        path = dir.join("sample.wav").to_s
        File.binwrite(path, file.read)
        path
      end

      def serialize(voice_profile)
        {
          id: voice_profile.id,
          status: voice_profile.status,
          kokoro_profile_id: voice_profile.kokoro_profile_id,
          created_at: voice_profile.created_at
        }
      end
    end
  end
end
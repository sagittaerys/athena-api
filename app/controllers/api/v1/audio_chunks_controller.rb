module Api
  module V1
    class AudioChunksController < ApplicationController
      def create
        library_item = current_user.library_items.find_by(id: params[:library_item_id])

        unless library_item
          render json: { error: "Library item not found" }, status: :not_found
          return
        end

        voice_profile = current_user.voice_profiles.find_by(status: "ready")

        unless voice_profile
          render json: { error: "No ready voice profile found" }, status: :unprocessable_entity
          return
        end

        existing = AudioChunk.find_by(
          library_item: library_item,
          user: current_user,
          chapter_index: params[:chapter_index],
          chunk_index: params[:chunk_index]
        )

        if existing&.ready?
          render json: { audio_chunk: serialize(existing) }, status: :ok
          return
        end

        chunk = AudioChunk.find_or_initialize_by(
          library_item: library_item,
          user: current_user,
          chapter_index: params[:chapter_index].to_i,
          chunk_index: params[:chunk_index].to_i
        )

        chunk.status = "pending"
        chunk.save!

        begin
          audio_data = TtsService.synthesize(
            voice_profile_id: voice_profile.kokoro_profile_id,
            text: params[:text],
            chapter_index: params[:chapter_index].to_i,
            chunk_index: params[:chunk_index].to_i
          )

          audio_url = save_audio(audio_data, library_item.id, params[:chapter_index], params[:chunk_index])

          chunk.update!(
            audio_url: audio_url,
            status: "ready"
          )

          render json: { audio_chunk: serialize(chunk) }, status: :created

        rescue => e
          chunk.update!(status: "failed")
          Rails.logger.error "Audio synthesis failed: #{e.message}"
          render json: { error: "Audio synthesis failed" }, status: :internal_server_error
        end
      end

      def show
        chunk = AudioChunk.find_by(
          id: params[:id],
          user: current_user
        )

        if chunk
          render json: { audio_chunk: serialize(chunk) }, status: :ok
        else
          render json: { error: "Not found" }, status: :not_found
        end
      end

      private

      def save_audio(audio_data, library_item_id, chapter_index, chunk_index)
        dir = Rails.root.join("storage", "audio", library_item_id.to_s, chapter_index.to_s)
        FileUtils.mkdir_p(dir)
        filename = "chunk_#{chunk_index}.wav"
        path = dir.join(filename).to_s
        File.binwrite(path, audio_data)
        path
      end

      def serialize(chunk)
        {
          id: chunk.id,
          chapter_index: chunk.chapter_index,
          chunk_index: chunk.chunk_index,
          audio_url: chunk.audio_url,
          status: chunk.status
        }
      end
    end
  end
end

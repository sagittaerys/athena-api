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

        chunk = AudioChunk.find_or_initialize_by(
          library_item: library_item,
          user: current_user,
          chapter_index: params[:chapter_index].to_i,
          chunk_index: params[:chunk_index].to_i
        )

        if chunk.ready?
          render json: { audio_chunk: serialize(chunk) }, status: :ok
          return
        end

        chunk.assign_attributes(
          text: params[:text],
          status: "pending"
        )
        chunk.save!

        AudioSynthesisJob.perform_later(chunk.id)

        render json: { audio_chunk: serialize(chunk) }, status: :accepted
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

      def stream
          chunk = AudioChunk.find_by(
            id: params[:id],
            user: current_user
          )

          unless chunk
            render json: { error: "Not found" }, status: :not_found
            return
          end

          unless chunk.ready?
            render json: { error: "Audio not ready yet", status: chunk.status },
                  status: :accepted
            return
          end

          audio_path = chunk.audio_url
          allowed_dir = Rails.root.join("storage", "audio").to_s

          unless audio_path&.start_with?(allowed_dir)
            render json: { error: "Invalid file path" }, status: :forbidden
            return
          end

          unless File.exist?(audio_path)
            render json: { error: "Audio file not found" }, status: :not_found
            return
          end

          send_file audio_path,
              type: "audio/wav",
              disposition: "inline",
              filename: "chunk_#{chunk.chapter_index}_#{chunk.chunk_index}.wav"
        end

      private

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

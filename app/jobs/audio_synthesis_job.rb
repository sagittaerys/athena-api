class AudioSynthesisJob < ApplicationJob
  queue_as :default

  def perform(audio_chunk_id)
    chunk = AudioChunk.find_by(id: audio_chunk_id)
    return unless chunk
    return if chunk.ready?

    voice_profile = chunk.user.voice_profiles.find_by(status: "ready")
    unless voice_profile
      chunk.update!(status: "failed")
      return
    end

    begin
      audio_data = TtsService.synthesize(
        voice_profile_id: voice_profile.kokoro_profile_id,
        text: chunk.text,
        chapter_index: chunk.chapter_index,
        chunk_index: chunk.chunk_index
      )

      audio_url = save_audio(
        audio_data,
        chunk.library_item_id,
        chunk.chapter_index,
        chunk.chunk_index
      )

      chunk.update!(
        audio_url: audio_url,
        status: "ready"
      )

    rescue => e
      Rails.logger.error "AudioSynthesisJob failed for chunk #{audio_chunk_id}: #{e.message}"
      chunk.update!(status: "failed")
    end
  end

  private

  def save_audio(audio_data, library_item_id, chapter_index, chunk_index)
    dir = Rails.root.join("storage", "audio", library_item_id.to_s, chapter_index.to_s)
    FileUtils.mkdir_p(dir)
    path = dir.join("chunk_#{chunk_index}.wav").to_s
    File.binwrite(path, audio_data)
    path
  end
end

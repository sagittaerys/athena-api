class TtsService
  TTS_SERVER_URL = ENV.fetch("TTS_SERVER_URL", "http://localhost:8000")
  TTS_SECRET_KEY = ENV.fetch("TTS_SECRET_KEY", "")

  def self.clone_voice(audio_file_path)
    uri = URI("#{TTS_SERVER_URL}/clone/")
    
    Net::HTTP.start(uri.host, uri.port) do |http|
      request = Net::HTTP::Post.new(uri)
      request["x-secret-key"] = TTS_SECRET_KEY
      
      form_data = [
        ["file", File.open(audio_file_path), { filename: "sample.wav", content_type: "audio/wav" }]
      ]
      request.set_form(form_data, "multipart/form-data")
      
      response = http.request(request)
      
      unless response.is_a?(Net::HTTPSuccess)
        raise "TTS server error: #{response.code} #{response.body}"
      end
      
      JSON.parse(response.body)
    end
  rescue => e
    Rails.logger.error "Voice cloning failed: #{e.message}"
    raise
  end

  def self.synthesize(voice_profile_id:, text:, chapter_index:, chunk_index:)
    uri = URI("#{TTS_SERVER_URL}/synthesize/")
    
    Net::HTTP.start(uri.host, uri.port) do |http|
      request = Net::HTTP::Post.new(uri)
      request["x-secret-key"] = TTS_SECRET_KEY
      request["Content-Type"] = "application/json"
      request.body = {
        voice_profile_id: voice_profile_id,
        text: text,
        chapter_index: chapter_index,
        chunk_index: chunk_index
      }.to_json
      
      response = http.request(request)
      
      unless response.is_a?(Net::HTTPSuccess)
        raise "TTS server error: #{response.code} #{response.body}"
      end
      
      response.body
    end
  rescue => e
    Rails.logger.error "Synthesis failed: #{e.message}"
    raise
  end

  def self.health_check
    uri = URI("#{TTS_SERVER_URL}/health")
    response = Net::HTTP.get_response(uri)
    response.is_a?(Net::HTTPSuccess)
  rescue
    false
  end
end
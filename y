{
  "ignored_warnings": [
    {
      "warning_type": "File Access",
      "warning_code": 16,
      "fingerprint": "2ff9c851dbc08d78dc0846b7ef0e6b966362d6a53060a0b4f83eee4bdfbd480d",
      "check_name": "SendFile",
      "message": "Model attribute used in file name",
      "file": "app/controllers/api/v1/audio_chunks_controller.rb",
      "line": 85,
      "link": "https://brakemanscanner.org/docs/warning_types/file_access/",
      "code": "send_file(AudioChunk.find_by(:id => params[:id], :user => current_user).audio_url, :type => \"audio/wav\", :disposition => \"inline\", :filename => (\"chunk_#{AudioChunk.find_by(:id => params[:id], :user => current_user).chapter_index}_#{AudioChunk.find_by(:id => params[:id], :user => current_user).chunk_index}.wav\"))",
      "render_path": null,
      "location": {
        "type": "method",
        "class": "Api::V1::AudioChunksController",
        "method": "stream"
      },
      "user_input": "AudioChunk.find_by(:id => params[:id], :user => current_user).audio_url",
      "confidence": "Medium",
      "cwe_id": [
        22
      ],
      "note": ""
    }
  ],
  "brakeman_version": "8.0.4"
}

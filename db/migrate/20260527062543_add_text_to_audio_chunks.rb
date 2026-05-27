class AddTextToAudioChunks < ActiveRecord::Migration[8.1]
  def change
    add_column :audio_chunks, :text, :text
  end
end

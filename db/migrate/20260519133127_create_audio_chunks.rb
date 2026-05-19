class CreateAudioChunks < ActiveRecord::Migration[8.1]
  def change
    create_table :audio_chunks do |t|
      t.references :user, null: false, foreign_key: true
      t.references :library_item, null: false, foreign_key: true
      t.integer :chapter_index, null: false
      t.integer :chunk_index, null: false
      t.string :audio_url
      t.string :status, null: false, default: "pending"

      t.timestamps
    end

    add_index :audio_chunks, [:user_id, :library_item_id, :chapter_index]
    add_index :audio_chunks, [:user_id, :library_item_id, :chapter_index, :chunk_index],
              unique: true,
              name: "index_audio_chunks_uniqueness"
  end
end
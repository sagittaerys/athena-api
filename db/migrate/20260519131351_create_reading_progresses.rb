class CreateReadingProgresses < ActiveRecord::Migration[8.1]
  def change
    create_table :reading_progresses do |t|
      t.references :user, null: false, foreign_key: true
      t.references :library_item, null: false, foreign_key: true
      t.integer :current_chapter, default: 0, null: false
      t.float :position_seconds, default: 0.0, null: false
      t.boolean :completed, default: false, null: false
      t.datetime :last_read_at

      t.timestamps
    end

    add_index :reading_progresses, [ :user_id, :library_item_id ], unique: true
  end
end

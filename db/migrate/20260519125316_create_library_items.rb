class CreateLibraryItems < ActiveRecord::Migration[8.1]
  def change
    create_table :library_items do |t|
      t.references :user, null: false, foreign_key: true
      t.string :external_id
      t.string :source, null: false
      t.string :title, null: false
      t.string :author
      t.string :cover_url
      t.string :epub_url

      t.timestamps
    end

    add_index :library_items, [ :user_id, :external_id ], unique: true
  end
end

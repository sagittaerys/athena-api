class CreateRefreshTokens < ActiveRecord::Migration[8.1]
  def change
    create_table :refresh_tokens do |t|
      t.references :user, null: false, foreign_key: true
      t.string :token_digest, null: false
      t.string :jti, null: false
      t.datetime :expires_at, null: false
      t.boolean :revoked, default: false

      t.timestamps
    end

    add_index :refresh_tokens, :jti, unique: true
  end
end

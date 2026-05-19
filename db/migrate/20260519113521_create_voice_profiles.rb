class CreateVoiceProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :voice_profiles do |t|
      t.references :user, null: false, foreign_key: true
      t.string :kokoro_profile_id
      t.string :sample_url
      t.string :status, default: "pending", null: false

      t.timestamps
    end
  end
end

# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_05_19_133127) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "audio_chunks", force: :cascade do |t|
    t.string "audio_url"
    t.integer "chapter_index", null: false
    t.integer "chunk_index", null: false
    t.datetime "created_at", null: false
    t.bigint "library_item_id", null: false
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["library_item_id"], name: "index_audio_chunks_on_library_item_id"
    t.index ["user_id", "library_item_id", "chapter_index", "chunk_index"], name: "index_audio_chunks_uniqueness", unique: true
    t.index ["user_id", "library_item_id", "chapter_index"], name: "idx_on_user_id_library_item_id_chapter_index_cc150b7db1"
    t.index ["user_id"], name: "index_audio_chunks_on_user_id"
  end

  create_table "library_items", force: :cascade do |t|
    t.string "author"
    t.string "cover_url"
    t.datetime "created_at", null: false
    t.string "epub_url"
    t.string "external_id"
    t.string "source", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "external_id"], name: "index_library_items_on_user_id_and_external_id", unique: true
    t.index ["user_id"], name: "index_library_items_on_user_id"
  end

  create_table "reading_progresses", force: :cascade do |t|
    t.boolean "completed", default: false, null: false
    t.datetime "created_at", null: false
    t.integer "current_chapter", default: 0, null: false
    t.datetime "last_read_at"
    t.bigint "library_item_id", null: false
    t.float "position_seconds", default: 0.0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["library_item_id"], name: "index_reading_progresses_on_library_item_id"
    t.index ["user_id", "library_item_id"], name: "index_reading_progresses_on_user_id_and_library_item_id", unique: true
    t.index ["user_id"], name: "index_reading_progresses_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.string "username", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "voice_profiles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "kokoro_profile_id"
    t.string "sample_url"
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_voice_profiles_on_user_id"
  end

  add_foreign_key "audio_chunks", "library_items"
  add_foreign_key "audio_chunks", "users"
  add_foreign_key "library_items", "users"
  add_foreign_key "reading_progresses", "library_items"
  add_foreign_key "reading_progresses", "users"
  add_foreign_key "voice_profiles", "users"
end

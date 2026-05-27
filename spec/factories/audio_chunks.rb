FactoryBot.define do
  factory :audio_chunk do
    association :user
    association :library_item
    chapter_index { 1 }
    chunk_index { 1 }
    audio_url { nil }
    status { "pending" }
    text { "It is a truth universally acknowledged." }
  end
end
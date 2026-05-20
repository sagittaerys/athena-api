FactoryBot.define do
  factory :reading_progress do
    association :user
    association :library_item
    current_chapter { 0 }
    position_seconds { 0.0 }
    completed { false }
    last_read_at { nil }
  end
end

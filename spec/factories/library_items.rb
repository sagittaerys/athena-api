FactoryBot.define do
  factory :library_item do
    association :user
    external_id { nil }
    source { "imported" }
    title { Faker::Book.title }
    author { Faker::Book.author }
    cover_url { nil }
    epub_url { nil }
  end
end

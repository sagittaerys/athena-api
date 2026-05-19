FactoryBot.define do
  factory :voice_profile do
    association :user
    kokoro_profile_id { nil }
    sample_url { nil }
    status { "pending" }
  end
end

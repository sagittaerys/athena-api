FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@athena.com" }
    sequence(:username) { |n| "user_#{n}" }
    password { "password123" }
  end
end
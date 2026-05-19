FactoryBot.define do
  factory :user do
    email { Faker::Internet.unique.email }
    username { "#{Faker::Internet.username(specifier: 3..20).gsub(/[^a-zA-Z0-9_]/, '_')}" }
    password_digest { "password123" }
  end
end

FactoryBot.define do
  factory :user do
    sequence(:username) { |n| "user#{n}" }
    sequence(:email) { |n| "user#{n}@example.com" }
    password { 'password123' }
    password_confirmation { 'password123' }
    karma_score { 0 }
    is_active { true }
    is_verified { false }

    trait :verified do
      is_verified { true }
    end

    trait :with_karma do
      karma_score { 100 }
    end
  end
end

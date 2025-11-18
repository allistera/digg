FactoryBot.define do
  factory :article do
    association :user
    association :category
    sequence(:title) { |n| "Interesting Article About Technology #{n}" }
    sequence(:url) { |n| "https://example.com/article-#{n}" }
    description { 'A comprehensive guide to modern technology' }
    thumbnail_url { nil }
    domain { 'example.com' }
    vote_count { 0 }
    comment_count { 0 }
    view_count { 0 }
    hotness_score { 0.0 }
    status { 'published' }

    trait :pending do
      status { 'pending' }
    end

    trait :approved do
      status { 'approved' }
    end
  end
end

FactoryBot.define do
  factory :category do
    sequence(:name) { |n| "Category #{n}" }
    sequence(:slug) { |n| "category-#{n}" }
    description { 'A test category' }
    display_order { 0 }
    parent_id { nil }
  end
end

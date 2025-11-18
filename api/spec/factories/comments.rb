FactoryBot.define do
  factory :comment do
    association :user
    association :article
    content { 'This is a test comment with some meaningful content.' }
    parent_id { nil }
    path { '' }
    depth { 0 }
    vote_count { 0 }
    is_deleted { false }

    trait :deleted do
      is_deleted { true }
    end

    trait :with_parent do
      transient do
        parent { nil }
      end

      after(:build) do |comment, evaluator|
        if evaluator.parent
          comment.parent_id = evaluator.parent.id
          comment.depth = evaluator.parent.depth + 1
        end
      end
    end
  end
end

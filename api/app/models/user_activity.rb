class UserActivity < ApplicationRecord
  belongs_to :user
  belongs_to :user
  belongs_to :entity, polymorphic: true

  validates :activity_type, inclusion: { in: %w[submit upvote downvote comment] }

  scope :recent, -> { order(created_at: :desc) }
  scope :by_type, ->(type) { where(activity_type: type) }
end

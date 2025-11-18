class Report < ApplicationRecord
  belongs_to :reporter, class_name: 'User'
  belongs_to :resolver, class_name: 'User', optional: true
  belongs_to :reportable, polymorphic: true

  validates :reason, presence: true, length: { minimum: 10, maximum: 500 }
  validates :status, inclusion: { in: %w[pending resolved dismissed] }

  before_create :set_defaults

  scope :pending, -> { where(status: 'pending') }
  scope :resolved, -> { where(status: 'resolved') }
  scope :dismissed, -> { where(status: 'dismissed') }
  scope :recent, -> { order(created_at: :desc) }

  def resolve!(resolver_user)
    update!(status: 'resolved', resolver: resolver_user, resolved_at: Time.current)
  end

  def dismiss!(resolver_user)
    update!(status: 'dismissed', resolver: resolver_user, resolved_at: Time.current)
  end

  private

  def set_defaults
    self.status ||= 'pending'
  end
end

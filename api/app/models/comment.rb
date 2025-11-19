class Comment < ApplicationRecord
  belongs_to :article
  belongs_to :user
  belongs_to :parent, class_name: 'Comment', optional: true

  has_many :replies, class_name: 'Comment', foreign_key: :parent_id, dependent: :destroy
  has_many :comment_votes, dependent: :destroy
  has_many :reports, as: :reportable, dependent: :destroy

  validates :content, presence: true, length: { minimum: 1, maximum: 10_000 }

  before_create :set_defaults, :set_path_and_depth
  after_create :increment_article_comment_count, :create_comment_activity

  scope :active, -> { where(is_deleted: false) }
  scope :root_comments, -> { where(parent_id: nil) }
  scope :recent, -> { order(created_at: :desc) }

  def vote_up!(user)
    vote = comment_votes.find_or_initialize_by(user: user)
    vote.vote_type = 1
    vote.save!
    update_vote_count
  end

  def vote_down!(user)
    vote = comment_votes.find_or_initialize_by(user: user)
    vote.vote_type = -1
    vote.save!
    update_vote_count
  end

  def unvote!(user)
    vote = comment_votes.find_by(user: user)
    vote&.destroy
    update_vote_count
  end

  def update_vote_count
    update(vote_count: comment_votes.sum(:vote_type))
  end

  def soft_delete
    update(is_deleted: true)
    article.update_comment_count
  end

  def children
    Comment.where("path LIKE ?", "#{path}.%")
  end

  private

  def set_defaults
    self.vote_count ||= 0
    self.is_deleted = false if is_deleted.nil?
  end

  def set_path_and_depth
    if parent
      self.path = "#{parent.path}.#{parent.id}"
      self.depth = parent.depth + 1
    else
      self.path = ''
      self.depth = 0
    end
  end

  def increment_article_comment_count
    article.update_comment_count
  end

  def create_comment_activity
    user.user_activities.create!(
      activity_type: 'comment',
      entity: self,
      points: 1
    )
  end
end

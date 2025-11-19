class Article < ApplicationRecord
  belongs_to :user
  belongs_to :category

  has_many :article_tags, dependent: :destroy
  has_many :tags, through: :article_tags
  has_many :comments, dependent: :destroy
  has_many :article_votes, dependent: :destroy
  has_many :saved_articles, dependent: :destroy
  has_many :reports, as: :reportable, dependent: :destroy

  validates :title, presence: true, length: { minimum: 10, maximum: 200 }
  validates :url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }
  validates :status, inclusion: { in: %w[pending approved published] }

  before_create :set_defaults
  after_create :create_submit_activity

  scope :published, -> { where(status: 'published') }
  scope :approved, -> { where(status: 'approved') }
  scope :pending, -> { where(status: 'pending') }
  scope :hot, -> { where('hotness_score > ?', 0).order(hotness_score: :desc) }
  scope :trending, -> { where('created_at > ?', 24.hours.ago).order(vote_count: :desc) }
  scope :recent, -> { order(created_at: :desc) }

  def vote_up!(user)
    vote = article_votes.find_or_initialize_by(user: user)
    vote.vote_type = 1
    vote.save!
    update_vote_count
    create_vote_activity(user, 1)
  end

  def vote_down!(user)
    vote = article_votes.find_or_initialize_by(user: user)
    vote.vote_type = -1
    vote.save!
    update_vote_count
    create_vote_activity(user, -1)
  end

  def unvote!(user)
    vote = article_votes.find_by(user: user)
    vote&.destroy
    update_vote_count
  end

  def update_vote_count
    update(vote_count: article_votes.sum(:vote_type))
  end

  def update_comment_count
    update(comment_count: comments.where(is_deleted: false).count)
  end

  def increment_views
    increment!(:view_count)
  end

  def calculate_hotness
    score = vote_count
    hours_old = (Time.current - created_at) / 3600.0
    self.hotness_score = score / ((hours_old + 2) ** 1.5)
    save
  end

  private

  def set_defaults
    self.status ||= 'pending'
    self.vote_count ||= 0
    self.comment_count ||= 0
    self.view_count ||= 0
    self.hotness_score ||= 0.0
  end

  def create_submit_activity
    user.user_activities.create!(
      activity_type: 'submit',
      entity: self,
      points: 1
    )
  end

  def create_vote_activity(voter, vote_type)
    voter.user_activities.create!(
      activity_type: vote_type > 0 ? 'upvote' : 'downvote',
      entity: self,
      points: 0
    )
  end
end

class User < ApplicationRecord
  has_secure_password

  has_many :articles, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :article_votes, dependent: :destroy
  has_many :comment_votes, dependent: :destroy
  has_many :saved_articles, dependent: :destroy
  has_many :user_activities, dependent: :destroy
  has_many :reports, foreign_key: :reporter_id, dependent: :destroy

  has_many :follower_relationships, class_name: 'UserFollow', foreign_key: :followed_id, dependent: :destroy
  has_many :followers, through: :follower_relationships, source: :follower

  has_many :following_relationships, class_name: 'UserFollow', foreign_key: :follower_id, dependent: :destroy
  has_many :following, through: :following_relationships, source: :followed

  has_many :category_subscriptions, dependent: :destroy
  has_many :subscribed_categories, through: :category_subscriptions, source: :category

  validates :username, presence: true, uniqueness: { case_sensitive: false }, length: { minimum: 3, maximum: 30 }
  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :karma_score, numericality: { greater_than_or_equal_to: 0 }

  before_create :set_defaults

  scope :active, -> { where(is_active: true) }
  scope :verified, -> { where(is_verified: true) }

  def calculate_karma
    user_activities.sum(:points)
  end

  def followers_count
    followers.count
  end

  def following_count
    following.count
  end

  private

  def set_defaults
    self.karma_score ||= 0
    self.is_active = true if is_active.nil?
    self.is_verified = false if is_verified.nil?
  end
end

class Tag < ApplicationRecord
  has_many :article_tags, dependent: :destroy
  has_many :articles, through: :article_tags

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :slug, presence: true, uniqueness: true

  before_validation :generate_slug, if: -> { slug.blank? }
  before_create :set_defaults

  scope :popular, -> { where('usage_count > ?', 0).order(usage_count: :desc) }
  scope :trending, -> { order(usage_count: :desc).limit(20) }

  def increment_usage
    increment!(:usage_count)
  end

  def decrement_usage
    decrement!(:usage_count) if usage_count > 0
  end

  private

  def generate_slug
    self.slug = name.parameterize if name.present?
  end

  def set_defaults
    self.usage_count ||= 0
  end
end

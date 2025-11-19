class Category < ApplicationRecord
  belongs_to :parent, class_name: 'Category', optional: true
  has_many :subcategories, class_name: 'Category', foreign_key: :parent_id, dependent: :destroy

  has_many :articles, dependent: :nullify
  has_many :category_subscriptions, dependent: :destroy
  has_many :subscribers, through: :category_subscriptions, source: :user

  validates :name, presence: true, uniqueness: { scope: :parent_id }
  validates :slug, presence: true, uniqueness: true

  before_validation :generate_slug, if: -> { slug.blank? }

  scope :root_categories, -> { where(parent_id: nil) }
  scope :ordered, -> { order(display_order: :asc, name: :asc) }

  def descendants
    Category.where("parent_id = ?", id)
  end

  def article_count
    articles.where(status: 'published').count
  end

  def subscriber_count
    subscribers.count
  end

  private

  def generate_slug
    self.slug = name.parameterize if name.present?
  end
end

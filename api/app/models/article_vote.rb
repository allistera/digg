class ArticleVote < ApplicationRecord
  belongs_to :article
  belongs_to :user

  validates :vote_type, inclusion: { in: [-1, 1] }
  validates :user_id, uniqueness: { scope: :article_id, message: 'has already voted on this article' }

  after_save :update_article_vote_count
  after_destroy :update_article_vote_count

  private

  def update_article_vote_count
    article.update_vote_count
  end
end

class CommentVote < ApplicationRecord
  belongs_to :comment
  belongs_to :user

  validates :vote_type, inclusion: { in: [-1, 1] }
  validates :user_id, uniqueness: { scope: :comment_id, message: 'has already voted on this comment' }

  after_save :update_comment_vote_count
  after_destroy :update_comment_vote_count

  private

  def update_comment_vote_count
    comment.update_vote_count
  end
end

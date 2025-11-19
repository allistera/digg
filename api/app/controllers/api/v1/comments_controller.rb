module Api
  module V1
    class CommentsController < ApplicationController
      before_action :authenticate_user!, only: [:create, :update, :destroy, :vote, :unvote]
      before_action :set_comment, only: [:show, :update, :destroy, :vote, :unvote]
      before_action :set_article, only: [:index, :create]

      def index
        @comments = @article.comments
                            .active
                            .root_comments
                            .includes(:user, :replies)
                            .page(params[:page])
                            .per(params[:per_page] || 50)
                            .order(created_at: :asc)

        render json: {
          comments: @comments.as_json(
            only: [:id, :content, :vote_count, :depth, :created_at],
            include: {
              user: { only: [:id, :username, :karma_score, :avatar_url] },
              replies: {
                only: [:id, :content, :vote_count, :depth, :created_at],
                include: { user: { only: [:id, :username, :karma_score] } }
              }
            }
          ),
          meta: pagination_meta(@comments)
        }
      end

      def show
        render json: @comment.as_json(
          only: [:id, :content, :vote_count, :depth, :parent_id, :created_at],
          include: {
            user: { only: [:id, :username, :karma_score, :avatar_url] },
            article: { only: [:id, :title] },
            replies: {
              only: [:id, :content, :vote_count, :depth, :created_at],
              include: { user: { only: [:id, :username, :karma_score] } }
            }
          }
        )
      end

      def create
        parent_comment = @article.comments.find(params[:parent_id]) if params[:parent_id]
        @comment = @article.comments.new(comment_params)
        @comment.user = current_user
        @comment.parent = parent_comment

        if @comment.save
          render json: @comment.as_json(
            only: [:id, :content, :vote_count, :depth, :parent_id, :created_at],
            include: { user: { only: [:id, :username, :karma_score] } }
          ), status: :created
        else
          render json: { errors: @comment.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        return render json: { error: 'Forbidden' }, status: :forbidden unless current_user == @comment.user

        if @comment.update(comment_params)
          render json: @comment.as_json(only: [:id, :content, :updated_at])
        else
          render json: { errors: @comment.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        return render json: { error: 'Forbidden' }, status: :forbidden unless current_user == @comment.user

        @comment.soft_delete
        render json: { message: 'Comment deleted' }
      end

      def vote
        vote_type = params[:vote_type].to_i
        if vote_type == 1
          @comment.vote_up!(current_user)
        elsif vote_type == -1
          @comment.vote_down!(current_user)
        else
          return render json: { error: 'Invalid vote type' }, status: :bad_request
        end

        render json: { vote_count: @comment.vote_count }
      end

      def unvote
        @comment.unvote!(current_user)
        render json: { vote_count: @comment.vote_count }
      end

      private

      def set_article
        if params[:article_id]
          @article = Article.find(params[:article_id])
        elsif params[:id]
          # For nested comments route (/comments/:id/comments), get article from parent comment
          parent_comment = Comment.find(params[:id])
          @article = parent_comment.article
        end
      end

      def set_comment
        @comment = Comment.find(params[:id])
      end

      def comment_params
        params.require(:comment).permit(:content)
      end

      def pagination_meta(collection)
        {
          current_page: collection.current_page,
          total_pages: collection.total_pages,
          total_count: collection.total_count
        }
      end
    end
  end
end

module Api
  module V1
    class FeedController < ApplicationController
      before_action :authenticate_user!

      def index
        subscribed_category_ids = current_user.subscribed_categories.pluck(:id)
        following_user_ids = current_user.following.pluck(:id)

        @articles = Article.published
                          .includes(:user, :category, :tags)
                          .where('category_id IN (?) OR user_id IN (?)', subscribed_category_ids, following_user_ids)
                          .page(params[:page])
                          .per(params[:per_page] || 20)
                          .order(created_at: :desc)

        render json: {
          articles: @articles.as_json(
            only: [:id, :title, :url, :description, :vote_count, :comment_count, :created_at],
            include: {
              user: { only: [:id, :username, :karma_score] },
              category: { only: [:id, :name, :slug] },
              tags: { only: [:id, :name, :slug] }
            }
          ),
          meta: pagination_meta(@articles)
        }
      end

      private

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

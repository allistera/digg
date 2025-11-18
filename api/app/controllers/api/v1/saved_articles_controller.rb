module Api
  module V1
    class SavedArticlesController < ApplicationController
      before_action :authenticate_user!

      def index
        @saved_articles = current_user.saved_articles
                                      .includes(article: [:user, :category])
                                      .page(params[:page])
                                      .per(params[:per_page] || 20)
                                      .order(created_at: :desc)

        render json: {
          saved_articles: @saved_articles.as_json(
            only: [:id, :created_at],
            include: {
              article: {
                only: [:id, :title, :url, :description, :vote_count, :comment_count],
                include: {
                  user: { only: [:id, :username] },
                  category: { only: [:id, :name] }
                }
              }
            }
          ),
          meta: pagination_meta(@saved_articles)
        }
      end

      def create
        article = Article.find(params[:article_id])
        @saved_article = current_user.saved_articles.new(article: article)

        if @saved_article.save
          render json: { message: 'Article saved successfully' }, status: :created
        else
          render json: { errors: @saved_article.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        @saved_article = current_user.saved_articles.find(params[:id])
        @saved_article.destroy
        render json: { message: 'Article removed from saved' }
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

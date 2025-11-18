module Api
  module V1
    class ArticlesController < ApplicationController
      before_action :authenticate_user!, only: [:create, :update, :destroy, :vote, :unvote]
      before_action :set_article, only: [:show, :update, :destroy, :vote, :unvote]

      def index
        @articles = Article.published
                          .includes(:user, :category, :tags)
                          .page(params[:page])
                          .per(params[:per_page] || 20)

        @articles = filter_articles(@articles)
        @articles = sort_articles(@articles)

        render json: {
          articles: @articles.as_json(
            only: [:id, :title, :url, :description, :vote_count, :comment_count, :view_count, :created_at],
            include: {
              user: { only: [:id, :username, :karma_score] },
              category: { only: [:id, :name, :slug] },
              tags: { only: [:id, :name, :slug] }
            }
          ),
          meta: pagination_meta(@articles)
        }
      end

      def show
        @article.increment_views
        render json: @article.as_json(
          only: [:id, :title, :url, :description, :thumbnail_url, :domain, :vote_count, :comment_count, :view_count, :created_at],
          include: {
            user: { only: [:id, :username, :karma_score, :avatar_url] },
            category: { only: [:id, :name, :slug] },
            tags: { only: [:id, :name, :slug] }
          }
        )
      end

      def create
        @article = current_user.articles.new(article_params)
        @article.domain = extract_domain(@article.url) if @article.url

        if @article.save
          add_tags if params[:tags].present?
          render json: @article, status: :created
        else
          render json: { errors: @article.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        return render json: { error: 'Forbidden' }, status: :forbidden unless current_user == @article.user

        if @article.update(article_update_params)
          render json: @article
        else
          render json: { errors: @article.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        return render json: { error: 'Forbidden' }, status: :forbidden unless current_user == @article.user

        @article.destroy
        head :no_content
      end

      def vote
        vote_type = params[:vote_type].to_i
        if vote_type == 1
          @article.vote_up!(current_user)
        elsif vote_type == -1
          @article.vote_down!(current_user)
        else
          return render json: { error: 'Invalid vote type' }, status: :bad_request
        end

        render json: { vote_count: @article.vote_count }
      end

      def unvote
        @article.unvote!(current_user)
        render json: { vote_count: @article.vote_count }
      end

      def trending
        @articles = Article.published.trending.limit(20)
        render json: @articles.as_json(
          only: [:id, :title, :url, :vote_count, :comment_count, :created_at],
          include: {
            user: { only: [:id, :username] },
            category: { only: [:id, :name] }
          }
        )
      end

      def hot
        @articles = Article.published.hot.limit(20)
        render json: @articles.as_json(
          only: [:id, :title, :url, :vote_count, :hotness_score, :created_at],
          include: {
            user: { only: [:id, :username] },
            category: { only: [:id, :name] }
          }
        )
      end

      private

      def set_article
        @article = Article.find(params[:id])
      end

      def article_params
        params.require(:article).permit(:title, :url, :description, :thumbnail_url, :category_id)
      end

      def article_update_params
        params.require(:article).permit(:title, :description, :thumbnail_url, :category_id)
      end

      def filter_articles(articles)
        articles = articles.where(category_id: params[:category_id]) if params[:category_id]
        articles = articles.where(user_id: params[:user_id]) if params[:user_id]
        articles = articles.joins(:tags).where(tags: { id: params[:tag_id] }) if params[:tag_id]
        articles
      end

      def sort_articles(articles)
        case params[:sort]
        when 'recent'
          articles.recent
        when 'hot'
          articles.hot
        when 'votes'
          articles.order(vote_count: :desc)
        else
          articles.order(created_at: :desc)
        end
      end

      def extract_domain(url)
        URI.parse(url).host
      rescue URI::InvalidURIError
        nil
      end

      def add_tags
        tag_names = params[:tags].is_a?(String) ? params[:tags].split(',').map(&:strip) : params[:tags]
        tag_names.each do |tag_name|
          tag = Tag.find_or_create_by(name: tag_name.downcase)
          @article.article_tags.create(tag: tag)
        end
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

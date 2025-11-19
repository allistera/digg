module Api
  module V1
    class UsersController < ApplicationController
      before_action :set_user, only: [:show, :update, :articles, :comments, :followers, :following]

      def index
        @users = User.active
                     .page(params[:page])
                     .per(params[:per_page] || 20)
                     .order(karma_score: :desc)

        render json: {
          users: @users.as_json(only: [:id, :username, :karma_score, :avatar_url, :created_at]),
          meta: pagination_meta(@users)
        }
      end

      def show
        render json: @user.as_json(
          only: [:id, :username, :email, :karma_score, :avatar_url, :bio, :website_url, :is_verified, :created_at],
          methods: [:followers_count, :following_count]
        )
      end

      def update
        authenticate_user!
        return unless current_user

        unless current_user == @user
          render json: { error: 'Forbidden' }, status: :forbidden
          return
        end

        if @user.update(user_update_params)
          render json: @user.as_json(only: [:id, :username, :email, :bio, :website_url, :avatar_url])
        else
          render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def articles
        @articles = @user.articles
                        .published
                        .page(params[:page])
                        .per(params[:per_page] || 20)
                        .order(created_at: :desc)

        render json: {
          articles: @articles.as_json(
            only: [:id, :title, :url, :vote_count, :comment_count, :created_at],
            include: { category: { only: [:id, :name, :slug] } }
          ),
          meta: pagination_meta(@articles)
        }
      end

      def comments
        @comments = @user.comments
                        .active
                        .page(params[:page])
                        .per(params[:per_page] || 20)
                        .order(created_at: :desc)

        render json: {
          comments: @comments.as_json(
            only: [:id, :content, :vote_count, :created_at],
            include: { article: { only: [:id, :title] } }
          ),
          meta: pagination_meta(@comments)
        }
      end

      def followers
        @followers = @user.followers
                          .page(params[:page])
                          .per(params[:per_page] || 20)

        render json: {
          followers: @followers.as_json(only: [:id, :username, :karma_score, :avatar_url]),
          meta: pagination_meta(@followers)
        }
      end

      def following
        @following = @user.following
                          .page(params[:page])
                          .per(params[:per_page] || 20)

        render json: {
          following: @following.as_json(only: [:id, :username, :karma_score, :avatar_url]),
          meta: pagination_meta(@following)
        }
      end

      private

      def set_user
        @user = User.find(params[:id])
      end

      def user_params
        params.require(:user).permit(:username, :email, :password, :password_confirmation)
      end

      def user_update_params
        params.require(:user).permit(:bio, :website_url, :avatar_url)
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

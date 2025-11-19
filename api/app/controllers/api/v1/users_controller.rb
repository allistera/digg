module Api
  module V1
    class UsersController < ApplicationController
      before_action :set_user, only: %i[show update articles comments followers following]
      before_action :authenticate_user!, only: %i[update]
      before_action :authorize_user!, only: %i[update]

      def index
        @users = User.active
                     .page(params[:page])
                     .per(per_page)
                     .order(karma_score: :desc)

        render json: {
          users: @users.as_json(only: user_index_attributes),
          meta: pagination_meta(@users)
        }
      end

      def show
        render json: @user.as_json(
          only: user_show_attributes,
          methods: %i[followers_count following_count]
        )
      end

      def update
        if @user.update(user_update_params)
          render json: @user.as_json(only: user_update_attributes)
        else
          render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def articles
        @articles = @user.articles
                        .published
                        .page(params[:page])
                        .per(per_page)
                        .order(created_at: :desc)

        render json: {
          articles: @articles.as_json(
            only: %i[id title url vote_count comment_count created_at],
            include: { category: { only: %i[id name slug] } }
          ),
          meta: pagination_meta(@articles)
        }
      end

      def comments
        @comments = @user.comments
                        .active
                        .page(params[:page])
                        .per(per_page)
                        .order(created_at: :desc)

        render json: {
          comments: @comments.as_json(
            only: %i[id content vote_count created_at],
            include: { article: { only: %i[id title] } }
          ),
          meta: pagination_meta(@comments)
        }
      end

      def followers
        @followers = @user.followers
                          .page(params[:page])
                          .per(per_page)

        render json: {
          followers: @followers.as_json(only: user_list_attributes),
          meta: pagination_meta(@followers)
        }
      end

      def following
        @following = @user.following
                          .page(params[:page])
                          .per(per_page)

        render json: {
          following: @following.as_json(only: user_list_attributes),
          meta: pagination_meta(@following)
        }
      end

      private

      def set_user
        @user = User.find(params[:id])
      end

      def authorize_user!
        return if current_user == @user

        render json: { error: 'Forbidden' }, status: :forbidden
      end

      def user_update_params
        params.require(:user).permit(:bio, :website_url, :avatar_url)
      end

      def user_index_attributes
        %i[id username karma_score avatar_url created_at]
      end

      def user_show_attributes
        %i[id username email karma_score avatar_url bio website_url is_verified created_at]
      end

      def user_update_attributes
        %i[id username email bio website_url avatar_url]
      end

      def user_list_attributes
        %i[id username karma_score avatar_url]
      end
    end
  end
end

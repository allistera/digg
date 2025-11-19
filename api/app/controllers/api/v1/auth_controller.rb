module Api
  module V1
    class AuthController < ApplicationController
      skip_before_action :authenticate_user!, only: [:login, :register, :refresh], raise: false

      # POST /api/v1/auth/register
      def register
        user = User.new(user_params)

        if user.save
          tokens = generate_tokens(user)
          render json: {
            user: user.as_json(only: [:id, :username, :email, :karma_score, :created_at]),
            access_token: tokens[:access_token],
            refresh_token: tokens[:refresh_token]
          }, status: :created
        else
          render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # POST /api/v1/auth/login
      def login
        user = User.find_by(email: params[:email])

        if user&.authenticate(params[:password])
          tokens = generate_tokens(user)
          render json: {
            user: user.as_json(only: [:id, :username, :email, :karma_score, :avatar_url, :is_verified]),
            access_token: tokens[:access_token],
            refresh_token: tokens[:refresh_token]
          }
        else
          render json: { error: 'Invalid email or password' }, status: :unauthorized
        end
      end

      # POST /api/v1/auth/refresh
      def refresh
        refresh_token = params[:refresh_token]
        decoded = JsonWebToken.decode(refresh_token)

        if decoded && decoded[:type] == 'refresh'
          user = User.find_by(id: decoded[:user_id])
          if user
            tokens = generate_tokens(user)
            render json: {
              access_token: tokens[:access_token],
              refresh_token: tokens[:refresh_token]
            }
          else
            render json: { error: 'Invalid refresh token' }, status: :unauthorized
          end
        else
          render json: { error: 'Invalid or expired refresh token' }, status: :unauthorized
        end
      end

      # GET /api/v1/auth/me
      def me
        authenticate_user!
        return unless current_user

        render json: current_user.as_json(
          only: [:id, :username, :email, :karma_score, :avatar_url, :bio, :website_url, :is_verified, :created_at],
          methods: [:followers_count, :following_count]
        )
      end

      private

      def user_params
        params.require(:user).permit(:username, :email, :password, :password_confirmation)
      end

      def generate_tokens(user)
        {
          access_token: JsonWebToken.encode_access_token(user.id),
          refresh_token: JsonWebToken.encode_refresh_token(user.id)
        }
      end
    end
  end
end

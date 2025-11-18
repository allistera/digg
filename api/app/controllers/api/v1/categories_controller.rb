module Api
  module V1
    class CategoriesController < ApplicationController
      before_action :authenticate_user!, only: [:subscribe, :unsubscribe]
      before_action :set_category, only: [:show, :subscribe, :unsubscribe]

      def index
        @categories = Category.root_categories
                              .ordered
                              .includes(:subcategories)

        render json: @categories.as_json(
          only: [:id, :name, :slug, :description, :display_order],
          include: {
            subcategories: { only: [:id, :name, :slug, :description] }
          }
        )
      end

      def show
        render json: @category.as_json(
          only: [:id, :name, :slug, :description, :display_order, :created_at],
          include: {
            subcategories: { only: [:id, :name, :slug] },
            parent: { only: [:id, :name, :slug] }
          },
          methods: [:article_count, :subscriber_count]
        )
      end

      def subscribe
        subscription = current_user.category_subscriptions.find_or_create_by(category: @category)
        if subscription.persisted?
          render json: { message: 'Subscribed successfully' }
        else
          render json: { errors: subscription.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def unsubscribe
        subscription = current_user.category_subscriptions.find_by(category: @category)
        if subscription
          subscription.destroy
          render json: { message: 'Unsubscribed successfully' }
        else
          render json: { error: 'Not subscribed to this category' }, status: :not_found
        end
      end

      private

      def set_category
        @category = Category.find_by!(slug: params[:id]) || Category.find(params[:id])
      end
    end
  end
end

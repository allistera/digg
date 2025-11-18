module Api
  module V1
    class TagsController < ApplicationController
      before_action :set_tag, only: [:show]

      def index
        @tags = Tag.popular
                   .page(params[:page])
                   .per(params[:per_page] || 50)

        render json: {
          tags: @tags.as_json(only: [:id, :name, :slug, :usage_count]),
          meta: pagination_meta(@tags)
        }
      end

      def show
        render json: @tag.as_json(
          only: [:id, :name, :slug, :usage_count, :created_at],
          methods: [:article_count]
        )
      end

      private

      def set_tag
        @tag = Tag.find_by!(slug: params[:id]) || Tag.find(params[:id])
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

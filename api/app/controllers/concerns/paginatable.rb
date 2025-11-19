module Paginatable
  extend ActiveSupport::Concern

  private

  def per_page
    [params[:per_page]&.to_i || 20, 100].min
  end

  def pagination_meta(collection)
    {
      current_page: collection.current_page,
      total_pages: collection.total_pages,
      total_count: collection.total_count
    }
  end
end

class ApplicationController < ActionController::API
  include Paginatable

  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity

  private

  def current_user
    return @current_user if defined?(@current_user)

    token = request.headers['Authorization']&.split(' ')&.last
    if token
      decoded = JsonWebToken.decode(token)
      @current_user = User.find_by(id: decoded[:user_id]) if decoded && decoded[:type] == 'access'
    end
    @current_user
  end

  def authenticate_user!
    render json: { error: 'Unauthorized' }, status: :unauthorized unless current_user
  end

  def not_found(exception)
    render json: { error: exception.message }, status: :not_found
  end

  def unprocessable_entity(exception)
    render json: { error: exception.message, details: exception.record.errors }, status: :unprocessable_entity
  end
end

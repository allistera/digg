module RequestHelpers
  def auth_token_for(user)
    JsonWebToken.encode_access_token(user.id)
  end

  def auth_headers(user)
    token = auth_token_for(user)
    { 'Authorization' => "Bearer #{token}" }
  end
end

RSpec.configure do |config|
  config.include RequestHelpers, type: :request
end

module RequestHelpers
  def sign_in(user)
    post '/api/v1/auth/login', params: {
      email: user.email,
      password: user.password || 'password123'
    }
  end

  def auth_headers(user)
    sign_in(user)
    { 'Cookie' => response.headers['Set-Cookie'] }
  end
end

RSpec.configure do |config|
  config.include RequestHelpers, type: :request
end

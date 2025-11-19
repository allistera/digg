class JsonWebToken
  SECRET_KEY = Rails.application.credentials.secret_key_base || 'development_secret_key'

  # Encode a payload into a JWT token
  # @param payload [Hash] The data to encode
  # @param exp [Integer] Expiration time in hours (default: 24 hours)
  # @return [String] JWT token
  def self.encode(payload, exp = 24.hours.from_now)
    payload[:exp] = exp.to_i
    JWT.encode(payload, SECRET_KEY, 'HS256')
  end

  # Decode a JWT token
  # @param token [String] The JWT token to decode
  # @return [HashWithIndifferentAccess] Decoded payload
  def self.decode(token)
    decoded = JWT.decode(token, SECRET_KEY, true, algorithm: 'HS256')[0]
    HashWithIndifferentAccess.new(decoded)
  rescue JWT::DecodeError, JWT::ExpiredSignature => e
    nil
  end

  # Generate access token (short-lived)
  def self.encode_access_token(user_id)
    encode({ user_id: user_id, type: 'access' }, 1.hour.from_now)
  end

  # Generate refresh token (long-lived)
  def self.encode_refresh_token(user_id)
    encode({ user_id: user_id, type: 'refresh' }, 7.days.from_now)
  end
end

class JsonWebToken
  SECRET_KEY = Rails.application.secrets.secret_key_base.to_s

  def self.encode(payload, exp = 24.hours.from_now)
    payload[:exp] = exp.to_i
    JWT.encode(payload, SECRET_KEY, 'HS256')
  end

  def self.decode(token)
    decoded = JWT.decode(token, SECRET_KEY, true, algorithm: 'HS256')[0]
    HashWithIndifferentAccess.new(decoded)
  rescue JWT::DecodeError, JWT::ExpiredSignature
    nil
  end

  def self.encode_access_token(user_id)
    encode({ user_id: user_id, type: 'access' }, 1.hour.from_now)
  end

  def self.encode_refresh_token(user_id)
    encode({ user_id: user_id, type: 'refresh' }, 7.days.from_now)
  end
end

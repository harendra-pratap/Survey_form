module JsonWebToken
  SECRET_KEY = Rails.application.secret_key_base

  def self.encode_token(payload, exp = 24.hours.from_now)
    payload[:exp] = exp.to_i
    JWT.encode(payload, SECRET_KEY)
  end

  def self.decode_token(token)
    decoded = JWT.decode(token, SECRET_KEY, true, algorithm: 'HS256')
    decoded[0]
  rescue JWT::ExpiredSignature
    nil
  rescue JWT::DecodeError
    nil
  end
end

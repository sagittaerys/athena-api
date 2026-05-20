class JwtService
  SECRET_KEY = Rails.application.secret_key_base
  ACCESS_TOKEN_EXPIRY = 15.minutes
  REFRESH_TOKEN_EXPIRY = 30.days

  def self.generate_access_token(user_id)
    payload = {
      user_id: user_id,
      jti: SecureRandom.uuid,
      exp: ACCESS_TOKEN_EXPIRY.from_now.to_i,
      type: "access"
    }
    JWT.encode(payload, SECRET_KEY, "HS256")
  end

  def self.generate_refresh_token(user_id)
    raw_token = SecureRandom.hex(32)
    jti = SecureRandom.uuid

    RefreshToken.create!(
      user_id: user_id,
      token_digest: Digest::SHA256.hexdigest(raw_token),
      jti: jti,
      expires_at: REFRESH_TOKEN_EXPIRY.from_now
    )

    raw_token
  end

  def self.decode_access_token(token)
    payload = JWT.decode(token, SECRET_KEY, true, algorithm: "HS256").first
    return nil unless payload["type"] == "access"
    payload
  rescue JWT::ExpiredSignature, JWT::DecodeError
    nil
  end
end

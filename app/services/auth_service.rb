class AuthService
  class AuthenticationError < StandardError; end
  class InvalidTokenError < StandardError; end

  def self.register(email:, username:, password:)
    user = User.new(
      email: email,
      username: username,
      password: password
    )

    unless user.save
      raise AuthenticationError, user.errors.full_messages.join(",")
    end

    generate_tokens(user)
  end

  def self.login(email:, password:)
    user = User.find_by(email: email.downcase.strip)

    unless user&.authenticate(password)
      raise AuthenticationError, "Invalid email or password"
    end

    generate_tokens(user)
  end

  def self.refresh(raw_token:)
    token_record = RefreshToken.find_by_token(raw_token)

    unless token_record&.active?
      raise InvalidTokenError, "Invalid or expired refresh token"
    end

    token_record.revoke!
    generate_tokens(token_record.user)
  end

  def self.logout(raw_token:)
    token_record = RefreshToken.find_by_token(raw_token)
    token_record&.revoke!
  end


  private

  def self.generate_tokens(user)
    access_token = JwtService.generate_access_token(user.id)
    refresh_token = JwtService.generate_refresh_token(user.id)

    {
      user: user,
      access_token: access_token,
      refresh_token: refresh_token
    }
  end
end

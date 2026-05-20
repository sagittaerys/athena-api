require 'rails_helper'

RSpec.describe AuthService do
  let(:user) { create(:user) }

  describe ".register" do
    it "creates a new user" do
      expect {
        AuthService.register(
          email: "test@example.com",
          username: "testuser",
          password: "password"
        )
      }.to change(User, :count).by(1)
    end

    it "raises an error with invalid data" do
      expect {
        AuthService.register(
          email: "notanemail",
          username: "x",
          password: "sagittaerys"
        )
      }.to raise_error(AuthService::AuthenticationError)
    end
  end

  describe ".login" do
    it "returns a hash with user, access_token, and refresh_token" do
      result = AuthService.login(
        email: user.email,
        password: "password123"
      )

      expect(result).to include(:user, :access_token, :refresh_token)
    end

    it "raises an error with wrong password" do
      expect {
        AuthService.login(email: user.email, password: "wrongpassword")
      }.to raise_error(AuthService::AuthenticationError)
    end
  end

  describe ".refresh_tokens" do
    let(:refresh_token) { JwtService.generate_refresh_token(user.id) }

    it "returns new tokens for a valid refresh token" do
      result = AuthService.refresh(raw_token: refresh_token)
      expect(result).to include(:user, :access_token, :refresh_token)
    end

    it "raises an error for an invalid refresh token" do
      expect {
        AuthService.refresh(raw_token: "invalidtoken")
      }.to raise_error(AuthService::InvalidTokenError)
    end

  end

  describe ".logout" do
    let(:refresh_token) { JwtService.generate_refresh_token(user.id) }

    it "revokes the refresh token" do
      AuthService.logout(raw_token: refresh_token)
      token_record = RefreshToken.find_by_token(refresh_token)
      expect(token_record.revoked).to be(true)
    end

    it "revokes the old refresh token after refresh" do
      raw = refresh_token
      old_token_record = RefreshToken.last
      AuthService.refresh(raw_token: raw)
      expect(old_token_record.reload.revoked).to be(true)
    end
  end
end
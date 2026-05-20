require 'rails_helper'

RSpec.describe JwtService do
  let(:user) { create(:user) }

  describe ".generate_access_token" do
    it "returns a string" do
      token = JwtService.generate_access_token(user.id)
      expect(token).to be_a(String)
    end

    it "encodes the user_id in the payload" do
      token = JwtService.generate_access_token(user.id)
      payload = JwtService.decode_access_token(token)
      expect(payload["user_id"]).to eq(user.id)
    end

    it "sets type to access" do
      token = JwtService.generate_access_token(user.id)
      payload = JwtService.decode_access_token(token)
      expect(payload["type"]).to eq("access")
    end
  end

  describe ".generate_refresh_token" do
    it "returns a raw token string" do
      token = JwtService.generate_refresh_token(user.id)
      expect(token).to be_a(String)
    end

    it "saves a refresh token record to the database" do
      expect {
        JwtService.generate_refresh_token(user.id)
      }.to change(RefreshToken, :count).by(1)
    end

    it "never stores the raw token" do
      raw = JwtService.generate_refresh_token(user.id)
      token_record = RefreshToken.last
      expect(token_record.token_digest).not_to eq(raw)
    end
  end

  describe ".decode_access_token" do
    it "returns payload for valid token" do
      token = JwtService.generate_access_token(user.id)
      payload = JwtService.decode_access_token(token)
      expect(payload).not_to be_nil
    end

    it "returns nil for invalid token" do
      expect(JwtService.decode_access_token("invalid")).to be_nil
    end

    it "returns nil for expired token" do
      token = JwtService.generate_access_token(user.id)
      travel_to(20.minutes.from_now) do
        expect(JwtService.decode_access_token(token)).to be_nil
      end
    end

    it "returns nil when passed a refresh token" do
      raw = JwtService.generate_refresh_token(user.id)
      expect(JwtService.decode_access_token(raw)).to be_nil
    end
  end
end

require 'rails_helper'

RSpec.describe RefreshToken, type: :model do
  describe "associations" do
    it { should belong_to(:user) }
  end

  describe "validations" do
    subject(:refresh_token) { build(:refresh_token) }

    it { should validate_presence_of(:token_digest) }
    it { should validate_presence_of(:jti) }
    it { should validate_uniqueness_of(:jti) }
    it { should validate_presence_of(:expires_at) }
  end

  describe "scopes" do
    let!(:active_token) { create(:refresh_token, revoked: false, expires_at: 1.day.from_now) }
    let!(:revoked_token) { create(:refresh_token, revoked: true) }
    let!(:expired_token) { create(:refresh_token, revoked: false, expires_at: 1.day.ago) }

    it "returns active tokens" do
      expect(RefreshToken.active).to include(active_token)
      expect(RefreshToken.active).not_to include(revoked_token)
      expect(RefreshToken.active).not_to include(expired_token)
    end
  end

  describe "instance methods" do
    let(:refresh_token) { create(:refresh_token, revoked: false, expires_at: 1.day.from_now) }

    it "returns true for active? when not revoked and not expired" do
      expect(refresh_token.active?).to be(true)
    end

    it "returns false for active? when revoked" do
      refresh_token.update(revoked: true)
      expect(refresh_token.active?).to be(false)
    end

    it "returns false for active? when expired" do
      refresh_token.update(expires_at: 1.day.ago)
      expect(refresh_token.active?).to be(false)
    end
  end

  describe ".find_by_token" do
    it "finds token by raw value" do
      raw = SecureRandom.hex(32)
      digest = Digest::SHA256.hexdigest(raw)
      token = create(:refresh_token, token_digest: digest)
      expect(RefreshToken.find_by_token(raw)).to eq(token)
    end

    it "returns nil for invalid token" do
      expect(RefreshToken.find_by_token("invalid")).to be_nil
    end
  end

  describe "class methods" do
    describe ".revoke_all_for_user" do
      let(:user) { create(:user) }
      let!(:token1) { create(:refresh_token, user: user, revoked: false) }
      let!(:token2) { create(:refresh_token, user: user, revoked: false) }
      let!(:other_user_token) { create(:refresh_token, revoked: false) }

      it "revokes all tokens for the specified user" do
        RefreshToken.revoke_all_for_user(user.id)
        expect(token1.reload.revoked).to be(true)
        expect(token2.reload.revoked).to be(true)
        expect(other_user_token.reload.revoked).to be(false)
      end
    end
  end
end

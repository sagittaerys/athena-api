require 'rails_helper'

RSpec.describe User, type: :model do
  describe "validations" do
    subject(:user) { build(:user) }

    it { should validate_presence_of(:email) }
    it { should validate_presence_of(:username) }
    it { should validate_uniqueness_of(:email).case_insensitive }
    it { should validate_uniqueness_of(:username).case_insensitive }
    it { should validate_length_of(:username).is_at_least(3).is_at_most(30) }
    it { should validate_length_of(:password).is_at_least(8) }
  end

  describe "authentication" do
    let(:user) { create(:user, password: "password123") }

    it "authenticates with correct password" do
      expect(user.authenticate("password123")).to eq(user)
    end

    it "fails authentication with wrong password" do
      expect(user.authenticate("wrongpassword")).to be(false)
    end
  end

  describe "password security" do
    it "never stores plain text password" do
      user = create(:user, password: "password123")
      expect(user.password_digest).not_to eq("password123")
    end
  end

  describe "associations" do
    it { should have_many(:voice_profiles).dependent(:destroy) }
    it { should have_many(:library_items).dependent(:destroy) }
    it { should have_many(:reading_progresses).dependent(:destroy) }
    it { should have_many(:audio_chunks).dependent(:destroy) }
    it { should have_many(:refresh_tokens).dependent(:destroy) }
  end
end

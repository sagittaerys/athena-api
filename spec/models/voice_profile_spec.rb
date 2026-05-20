require 'rails_helper'

RSpec.describe VoiceProfile, type: :model do
  describe "associations" do
    it { should belong_to(:user) }
  end

  describe "validations" do
    it { should validate_inclusion_of(:status).in_array(VoiceProfile::STATUSES) }
  end

  describe "scopes" do
    let!(:pending_profile) { create(:voice_profile, status: "pending") }
    let!(:ready_profile)   { create(:voice_profile, status: "ready") }
    let!(:failed_profile)  { create(:voice_profile, status: "failed") }

    it "returns pending profiles" do
      expect(VoiceProfile.pending).to include(pending_profile)
    end

    it "returns ready profiles" do
      expect(VoiceProfile.ready).to include(ready_profile)
    end

    it "returns failed profiles" do
      expect(VoiceProfile.failed).to include(failed_profile)
    end
  end

  describe "predicate methods" do
    it "returns true for ready? when status is ready" do
      profile = build(:voice_profile, status: "ready")
      expect(profile.ready?).to be(true)
    end

    it "returns true for pending? when status is pending" do
      profile = build(:voice_profile, status: "pending")
      expect(profile.pending?).to be(true)
    end

    it "returns true for failed? when status is failed" do
      profile = build(:voice_profile, status: "failed")
      expect(profile.failed?).to be(true)
    end
  end
end

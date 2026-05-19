require 'rails_helper'

RSpec.describe ReadingProgress, type: :model do
  describe "associations" do
    it { should belong_to(:user) }
    it { should belong_to(:library_item) }
  end

  describe "validations" do
    subject(:progress) { build(:reading_progress) }

    it { should validate_numericality_of(:current_chapter)
                  .is_greater_than_or_equal_to(0) }
    it { should validate_numericality_of(:position_seconds)
                  .is_greater_than_or_equal_to(0.0) }

    it "prevents duplicate progress for same user and book" do
      user = create(:user)
      library_item = create(:library_item)
      create(:reading_progress, user: user, library_item: library_item)
      duplicate = build(:reading_progress, user: user, library_item: library_item)
      expect(duplicate).not_to be_valid
    end
  end

  describe "scopes" do
    let!(:completed_progress) { create(:reading_progress, completed: true, last_read_at: Time.current) }
    let!(:in_progress) { create(:reading_progress, completed: false, last_read_at: Time.current) }
    let!(:unstarted) { create(:reading_progress, completed: false, last_read_at: nil) }

    it "returns completed records" do
      expect(ReadingProgress.completed).to include(completed_progress)
    end

    it "returns in progress records" do
      expect(ReadingProgress.in_progress).to include(in_progress)
    end

    it "excludes unstarted from in progress" do
      expect(ReadingProgress.in_progress).not_to include(unstarted)
    end
  end

  describe "instance methods" do
    let(:progress) { create(:reading_progress) }

    it "marks as completed" do
      progress.mark_completed!
      expect(progress.reload.completed).to be(true)
    end

    it "updates position and last_read_at" do
      progress.update_position!(chapter: 3, seconds: 272.5)
      expect(progress.reload.current_chapter).to eq(3)
      expect(progress.reload.position_seconds).to eq(272.5)
      expect(progress.reload.last_read_at).not_to be_nil
    end
  end
end
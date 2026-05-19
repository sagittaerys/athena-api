require 'rails_helper'

RSpec.describe AudioChunk, type: :model do
  describe "associations" do
    it { should belong_to(:user) }
  end

  describe "validations" do
    it { should validate_inclusion_of(:status).in_array(AudioChunk::STATUSES) }
    it { should belong_to(:library_item) }
  end

  describe "scopes" do
    let!(:pending) { create(:audio_chunk, status: "pending") }
    let!(:ready)   { create(:audio_chunk, status: "ready") }
    let!(:failed)  { create(:audio_chunk, status: "failed") }
    let!(:chapter_one_chunk) { create(:audio_chunk, chapter_index: 1, chunk_index: 0) }
    let!(:chapter_two_chunk) { create(:audio_chunk, chapter_index: 2, chunk_index: 0) }

    it "returns pending chunks" do
      expect(AudioChunk.pending).to include(pending)
    end

    it "returns ready chunks" do
      expect(AudioChunk.ready).to include(ready)
    end

    it "returns chunks for a specific chapter" do
      expect(AudioChunk.by_chapter(1)).to include(chapter_one_chunk)
      expect(AudioChunk.by_chapter(1)).not_to include(chapter_two_chunk)
    end

    it "returns failed chunks" do
      expect(AudioChunk.failed).to include(failed)
    end
  end

  describe "predicate methods" do
    it "returns true for ready? when status is ready" do
      chunk = build(:audio_chunk, status: "ready")
      expect(chunk.ready?).to be(true)
    end

    it "returns true for pending? when status is pending" do
      chunk = build(:audio_chunk, status: "pending")
      expect(chunk.pending?).to be(true)
    end

    it "returns true for failed? when status is failed" do
      chunk = build(:audio_chunk, status: "failed")
      expect(chunk.failed?).to be(true)
    end
  end
end
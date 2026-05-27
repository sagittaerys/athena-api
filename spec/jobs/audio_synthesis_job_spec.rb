require "rails_helper"

RSpec.describe AudioSynthesisJob, type: :job do
  let(:user) { create(:user) }
  let(:voice_profile) { create(:voice_profile, user: user, status: "ready", kokoro_profile_id: "test-profile-id") }
  let(:library_item) { create(:library_item, user: user) }
  let(:audio_chunk) do
    create(:audio_chunk,
      user: user,
      library_item: library_item,
      chapter_index: 1,
      chunk_index: 0,
      text: "It is a truth universally acknowledged.",
      status: "pending"
    )
  end

  before { voice_profile }

  describe "#perform" do
    context "when synthesis succeeds" do
      before do
        allow(TtsService).to receive(:synthesize).and_return("fake_audio_data")
        allow(File).to receive(:binwrite)
        allow(FileUtils).to receive(:mkdir_p)
      end

      it "updates chunk status to ready" do
        described_class.perform_now(audio_chunk.id)
        expect(audio_chunk.reload.status).to eq("ready")
      end

      it "sets the audio_url" do
        described_class.perform_now(audio_chunk.id)
        expect(audio_chunk.reload.audio_url).not_to be_nil
      end

      it "calls TtsService with correct params" do
        expect(TtsService).to receive(:synthesize).with(
          voice_profile_id: voice_profile.kokoro_profile_id,
          text: audio_chunk.text,
          chapter_index: audio_chunk.chapter_index,
          chunk_index: audio_chunk.chunk_index
        ).and_return("fake_audio_data")

        described_class.perform_now(audio_chunk.id)
      end
    end

    context "when synthesis fails" do
      before do
        allow(TtsService).to receive(:synthesize).and_raise("TTS error")
      end

      it "updates chunk status to failed" do
        described_class.perform_now(audio_chunk.id)
        expect(audio_chunk.reload.status).to eq("failed")
      end
    end

    context "when chunk does not exist" do
      it "returns without error" do
        expect { described_class.perform_now(999999) }.not_to raise_error
      end
    end

    context "when chunk is already ready" do
      before { audio_chunk.update!(status: "ready") }

      it "does not call TtsService" do
        expect(TtsService).not_to receive(:synthesize)
        described_class.perform_now(audio_chunk.id)
      end
    end

    context "when no voice profile exists" do
      before { voice_profile.update!(status: "failed") }

      it "marks chunk as failed" do
        described_class.perform_now(audio_chunk.id)
        expect(audio_chunk.reload.status).to eq("failed")
      end
    end
  end
end
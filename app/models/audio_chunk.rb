class AudioChunk < ApplicationRecord
  belongs_to :user
  belongs_to :library_item

  STATUSES = %w[pending ready failed].freeze

  validates :chapter_index, numericality: { greater_than_or_equal_to: 0 }
  validates :chunk_index, numericality: { greater_than_or_equal_to: 0 }
  validates :status, inclusion: { in: STATUSES }

  scope :ready, -> { where(status: "ready") }
  scope :pending, -> { where(status: "pending") }
  scope :failed, -> { where(status: "failed") }
  scope :by_chapter, ->(chapter) { where(chapter_index: chapter).order(:chunk_index) }

  def ready?
    status == "ready"
  end

  def pending?
    status == "pending"
  end

  def failed?
    status == "failed"
  end
end

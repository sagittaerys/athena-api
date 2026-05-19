class ReadingProgress < ApplicationRecord
  belongs_to :user
  belongs_to :library_item

  validates :current_chapter, numericality: { greater_than_or_equal_to: 0 }
  validates :position_seconds, numericality: { greater_than_or_equal_to: 0.0 }
  validates :user_id, uniqueness: { scope: :library_item_id,
                                    message: "already has progress for this book" }

  scope :completed, -> { where(completed: true) }
  scope :in_progress, -> { where(completed: false).where.not(last_read_at: nil) }
  scope :recent, -> { order(last_read_at: :desc) }

  def mark_completed!
    update!(completed: true)
  end

  def update_position!(chapter:, seconds:)
    update!(
      current_chapter: chapter,
      position_seconds: seconds,
      last_read_at: Time.current
    )
  end
end
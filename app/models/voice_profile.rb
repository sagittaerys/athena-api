class VoiceProfile < ApplicationRecord
  belongs_to :user

  STATUSES = %w[pending ready failed].freeze

  validates :status, inclusion: { in: STATUSES }

  scope :ready, -> { where(status: "ready") }
  scope :pending, -> { where(status: "pending") }
  scope :failed, -> { where(status: "failed") }

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

class LibraryItem < ApplicationRecord
  belongs_to :user

  SOURCES = %w[gutenberg standard_ebooks open_library imported].freeze

  validates :title, presence: true
  validates :source, presence: true,
                     inclusion: { in: SOURCES }

  scope :by_source, ->(source) { where(source: source) }
  scope :imported, -> { where(source: "imported") }
  scope :from_catalog, -> { where.not(source: "imported") }
  scope :recent, -> { order(created_at: :desc) }
end
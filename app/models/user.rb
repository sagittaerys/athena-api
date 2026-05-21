class User < ApplicationRecord
  has_secure_password

  has_many :voice_profiles, dependent: :destroy
  has_many :library_items, dependent: :destroy
  has_many :reading_progresses, dependent: :destroy
  has_many :audio_chunks, dependent: :destroy
  has_many :refresh_tokens, dependent: :destroy

  validates :email,
            presence: true,
            uniqueness: { case_sensitive: false },
            format: { with: URI::MailTo::EMAIL_REGEXP }

  validates :username,
            presence: true,
            uniqueness: { case_sensitive: false },
            length: { minimum: 3, maximum: 30 },
            format: { with: /\A[a-zA-Z0-9_]+\z/,
                        message: "only allows letters, numbers, and underscores" }

  validates :password,
            length: { minimum: 8 },
            if: :password_required?

  private

  def password_required?
    new_record? || password.present?
  end
end

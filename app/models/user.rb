class User < ApplicationRecord
  has_secure_password

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

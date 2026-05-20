class RefreshToken < ApplicationRecord
  belongs_to :user

  validates :token_digest, presence: true
  validates :jti, presence: true, uniqueness: true
  validates :expires_at, presence: true

  scope :active, -> { where(revoked: false).where("expires_at > ?", Time.current) }

  def revoke!
    update!(revoked: true)
  end


  def active?
    !revoked && expires_at > Time.current
  end

  def self.find_by_token(raw_token)
    digest = Digest::SHA256.hexdigest(raw_token)
    find_by(token_digest: digest)
  end

  def self.revoke_all_for_user(user_id)
    where(user_id: user_id).update_all(revoked: true)
  end
end

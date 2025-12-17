# app/models/user.rb
#
# Core user identity for authentication and governance.
#
# One User can act as:
# - a writer
# - a freelancer
# - an admin
#
# Roles are added later; this model focuses on:
# - authentication
# - email verification
# - account lifecycle state (governance)
#
class User < ApplicationRecord
  # ------------------------------------------------------------------
  # Authentication (Rails built-in authentication generator)
  # ------------------------------------------------------------------
  has_secure_password
  has_many :sessions, dependent: :destroy

  # Normalise email to avoid duplicate accounts due to casing/spacing
  normalizes :email_address, with: ->(e) { e.strip.downcase }

  # ------------------------------------------------------------------
  # Validations
  # ------------------------------------------------------------------

  validates :email_address, presence: true, uniqueness: true


  # ------------------------------------------------------------------
  # Account lifecycle state
  # ------------------------------------------------------------------
  # NOTE:
  # `status` is governance-critical.
  # We prefer explicit lifecycle states over ad-hoc booleans so that
  # moderation, appeals, and anonymisation remain auditable.
  enum :status, {
    active: 0,
    deactivated: 1,
    suspended: 2,
    banned: 3,
    anonymised: 4
  }

  # ------------------------------------------------------------------
  # Email verification
  # ------------------------------------------------------------------
  # Email verification is a *capability gate*, not an account existence gate.
  #
  # Unverified users:
  # - can browse
  # - can read profiles
  # - can start onboarding
  #
  # Unverified users CANNOT:
  # - message other users
  # - post projects
  # - bid on work
  # - leave reviews
  #

  # Has this user verified their email address?
  def verified_email?
    email_verified_at.present?
  end

  # Can this user authenticate and maintain a session?
  # (Used later to force logout on deactivation / ban.)
  def can_authenticate?
    active? && !banned? && !anonymised? && !deactivated?
  end

  # ------------------------------------------------------------------
  # Email verification token handling
  # ------------------------------------------------------------------
  # We store a SHA-256 digest of the token (searchable), never the raw token.
  # This allows us to find the user by token digest without scanning all users.

  def generate_email_verification_token!
    raw_token = SecureRandom.urlsafe_base64(32)
    digest = self.class.email_token_digest(raw_token)

    update!(
      verification_token_digest: digest,
      verification_sent_at: Time.current
    )

    raw_token
  end

  def self.email_token_digest(raw_token)
    OpenSSL::Digest::SHA256.hexdigest(raw_token.to_s)
  end

  def valid_email_verification_token?(raw_token, expires_in: 2.days)
    return false if raw_token.blank?
    return false if verification_token_digest.blank? || verification_sent_at.blank?
    return false if verification_sent_at < expires_in.ago

    expected = self.class.email_token_digest(raw_token)
    ActiveSupport::SecurityUtils.secure_compare(verification_token_digest, expected)
  end

  def verify_email!
    update!(
      email_verified_at: Time.current,
      verification_token_digest: nil,
      verification_sent_at: nil
    )
  end
end

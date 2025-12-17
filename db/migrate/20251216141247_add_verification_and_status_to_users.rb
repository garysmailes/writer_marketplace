class AddVerificationAndStatusToUsers < ActiveRecord::Migration[8.0]
  # Email verification is required for “active” actions (messaging, posting, reviews).
  # Unverified users can browse and start onboarding, but remain soft-restricted.

  def change
    add_column :users, :email_verified_at, :datetime

    # We store only a digest of the verification token (never the raw token).
    add_column :users, :verification_token_digest, :string
    add_column :users, :verification_sent_at, :datetime

    # Account lifecycle state. Default is active.
    # (We'll add deactivated/suspended/banned/anonymised later.)
    add_column :users, :status, :integer, null: false, default: 0

    add_index :users, :email_verified_at
    add_index :users, :verification_token_digest, unique: true
    add_index :users, :status
  end
end

# app/controllers/email_verifications_controller.rb
#
# Handles email verification for account activation.
#
# Important:
# - Accounts exist immediately after sign-up
# - Sessions can start immediately
# - Email verification gates *active* actions only
#
class EmailVerificationsController < ApplicationController
  # Verification links are clicked from email, so they must be accessible
  # without an authenticated session.
  allow_unauthenticated_access only: [ :show ]

  # GET /verify_email/:token
  def show
    token  = params[:token].to_s
    digest = User.email_token_digest(token)

    user = User.find_by(verification_token_digest: digest)

    if user&.valid_email_verification_token?(token)
      user.verify_email!
      redirect_to root_path, notice: "Email verified. Your account is now active."
    else
      redirect_to new_session_path, alert: "That verification link is invalid or has expired."
    end
  end

  # POST /email_verification/resend
  #
  # User must be signed in, but may still be unverified.
  def create
    require_authentication!

    if Current.user.verified_email?
      redirect_to root_path, notice: "Your email is already verified."
      return
    end

    token = Current.user.generate_email_verification_token!
    EmailVerificationMailer
      .with(user: Current.user, token: token)
      .verify_email
      .deliver_later

    redirect_to root_path, notice: "Verification email sent. Please check your inbox."
  end
end

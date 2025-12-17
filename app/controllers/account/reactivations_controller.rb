# app/controllers/account/reactivations_controller.rb
#
# Signed-out account reactivation flow.
# NOTE: Must be accessible while logged out, so we inherit from ApplicationController
# and allow unauthenticated access explicitly.
#
class Account::ReactivationsController < ApplicationController
  allow_unauthenticated_access only: %i[new create show]

  def new
    # Optional: prefill email from query param
  end

  def create
    email = params[:email_address].to_s.strip.downcase
    user  = User.find_by(email_address: email)

    if user&.deactivated?
      AccountMailer.reactivation_email(user).deliver_later
    end

    # Always respond the same to prevent account enumeration
    redirect_to new_session_path, notice: "If an account exists for that email, we’ve sent a reactivation link."
  end

  def show
    user = User.find_signed!(params[:token], purpose: :reactivation)

    if user.active?
      redirect_to new_session_path, notice: "Your account is already active. Please sign in."
      return
    end

    user.update!(status: :active)

    # Defensive: invalidate any old sessions (reactivation should start fresh)
    user.sessions.delete_all

    redirect_to new_session_path, notice: "Your account has been reactivated. Please sign in."
  rescue ActiveSupport::MessageVerifier::InvalidSignature, ActiveRecord::RecordNotFound
    redirect_to new_session_path, alert: "That reactivation link is invalid or expired."
  end
end

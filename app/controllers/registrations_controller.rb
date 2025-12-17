# app/controllers/registrations_controller.rb
#
# Sign-up (account creation).
#
# Design:
# - Account is created immediately
# - Session starts immediately
# - Verification email is sent immediately
# - User is redirected to /activate
#
# Roles (writer/freelancer/both) are intentionally deferred.
#
class RegistrationsController < ApplicationController
  allow_unauthenticated_access only: [ :new, :create ]
  before_action :redirect_authenticated_user!, only: :new

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    @user.status = :active

    if @user.save
      # Start session immediately (activation is capability-gated elsewhere)
      start_new_session_for @user

      # Send verification email immediately
      token = @user.generate_email_verification_token!
      EmailVerificationMailer.with(user: @user, token: token).verify_email.deliver_later

      redirect_to activate_path, notice: "Account created. Please verify your email to activate your account."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:email_address, :password, :password_confirmation)
  end

  # Starts a session using the Rails authentication generator pattern.
  # This keeps registration controller small and consistent.
  def start_session_for(user)
    Session.create!(user: user, user_agent: request.user_agent, ip_address: request.remote_ip).tap do |session|
      cookies.signed.permanent[:session_token] = { value: session.id }
    end

    # Ensure Current is updated for this request
    Current.user = user
  end
end

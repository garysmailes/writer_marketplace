# app/controllers/concerns/access_control.rb
#
# Centralised access control for the app.
# --------------------------------------
# Governance-heavy apps die from inconsistent rules spread across controllers.
# This concern is the single source of truth for:
# - authentication
# - account lifecycle state (active/deactivated/etc.)
# - email verification capability gating
#
module AccessControl
  extend ActiveSupport::Concern

  private

  # Require a signed-in session.
  def require_authentication!
    return if authenticated?

    redirect_to new_session_path, alert: "Please sign in."
  end

  # Require an account in an active state.
  #
  # IMPORTANT:
  # Deactivated/banned/etc. users should be logged out immediately so they
  # cannot continue using an existing session.
  def require_active_account!
    require_authentication!
    return unless authenticated?

    return if Current.user&.active?

    force_logout!
    redirect_to new_session_path, alert: "Your account is not active."
  end

  # Require verified email for “active” marketplace actions.
  #
  # Unverified users may browse + start onboarding, but cannot:
  # message/post/bid/review/publish.
  def require_verified_email!
    return if Current.user&.verified_email?

    redirect_to activate_path, alert: "Please verify your email to activate your account."
  end


  # Destroy the current session and clear the Rails session cookie.
  # We keep this here so all forced-logout behaviour is consistent.
  def force_logout!
    Current.session&.destroy
    cookies.delete(:session_id)
    reset_session

    # Current only stores :session; user is delegated.
    Current.session = nil
  end

  # Redirect signed-in users away from logged-out-only pages
  def redirect_authenticated_user!
    return unless authenticated?

    redirect_to after_authentication_url
  end
end

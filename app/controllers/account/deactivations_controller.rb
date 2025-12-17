# app/controllers/account_deactivations_controller.rb
#
# Self-serve account deactivation.
#
# MVP policy:
# - Immediate effect
# - Logs the user out
# - Stops all activity

class Account::DeactivationsController < Account::BaseController
  before_action :require_active_account!

  def create
    user = Current.user

    user.update!(status: :deactivated)

    # Kill all sessions (other devices, old browsers, etc.)
    user.sessions.delete_all

    # Kill this session last
    terminate_session

    redirect_to new_session_path, notice: "Your account has been deactivated."
  end
end

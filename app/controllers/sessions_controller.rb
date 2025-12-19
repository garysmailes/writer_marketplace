class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]
  before_action :redirect_authenticated_user!, only: :new

  rate_limit to: 10, within: 3.minutes, only: :create,
             with: -> { redirect_to new_session_path, alert: "Try again later.", status: :see_other }

  def new
  end

  def create
    user = User.authenticate_by(params.permit(:email_address, :password))

    if user
      unless user.active?
        reactivate_url = reactivate_account_path(email_address: user.email_address)

        flash[:alert] = %(Your account is not active. <a href="#{reactivate_url}">Reactivate account?</a>)
        redirect_to new_session_path, status: :see_other
        return
      end

      start_new_session_for user
      redirect_to after_authentication_url, status: :see_other
    else
      redirect_to new_session_path, alert: "Try another email address or password.", status: :see_other
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path, status: :see_other
  end
end

# app/controllers/activations_controller.rb
#
# Activation landing page shown after sign-up.
# Users are allowed to sign in immediately, but must verify email to activate
# marketplace actions (messaging, posting, bidding, reviews).
#

class Account::ActivationsController < Account::BaseController
  def show
    redirect_to account_overview_path, notice: "Your email is already verified." if Current.user.verified_email?
  end
end

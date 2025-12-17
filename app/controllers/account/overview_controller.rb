# app/controllers/account_controller.rb
#
# Verified-only account home.
#
# This page exists to:
# - confirm access control rules are enforced
# - provide a stable landing surface for future account-level features
#
class Account::OverviewController < Account::BaseController
  before_action :require_verified_email!

  def show
  end
end

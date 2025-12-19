# app/controllers/account/base_controller.rb
#
# Base controller for all account-area controllers.
#
# Purpose:
# - Provide a single place for account-level behaviour
# - Keep authentication / governance rules consistent
# - Avoid duplication across Account:: controllers
#
# Design principles:
# - All account pages require authentication by default
# - Verification and other capability gates are applied per-controller
# - Business rules live in AccessControl, not here
#
class Account::BaseController < ApplicationController
  # All account-area pages require a signed-in user
  before_action :require_authentication!
  before_action :require_active_account!


  # NOTE:
  # Do NOT enforce email verification here.
  # Some account pages (e.g. /activate) must be accessible to unverified users.
end

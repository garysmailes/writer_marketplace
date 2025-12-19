# test/integration/account_access_test.rb
#
# Governance-critical access rules:
# - email verification gates "active" actions
# - non-active accounts are forcibly logged out (DB session destroyed)
#
require "test_helper"

class AccountAccessTest < ActionDispatch::IntegrationTest
  def create_user(email:, password:, verified: false, status: :active)
    user = User.create!(
      email_address: email,
      password: password,
      password_confirmation: password,
      status: status
    )
    user.update!(email_verified_at: Time.current) if verified
    user
  end

  def sign_in_as(user, password:)
    post session_path, params: { email_address: user.email_address, password: password }
    assert_response :redirect
  end

  test "unverified signed-in user is blocked from /account (redirects to /activate) and stays signed in" do
    user = create_user(email: "unverified@example.com", password: "password", verified: false)

    assert_difference "Session.count", +1 do
      sign_in_as(user, password: "password")
    end

    # Accessing /account should redirect to /activate, but NOT log the user out
    assert_no_difference "Session.count" do
      get account_overview_path
    end

    assert_response :redirect
    assert_redirected_to activate_path
  end

  test "verified signed-in user can access /account" do
    user = create_user(email: "verified@example.com", password: "password", verified: true)

    assert_difference "Session.count", +1 do
      sign_in_as(user, password: "password")
    end

    get account_overview_path
    assert_response :success
  end

  test "deactivated user is force-logged-out when attempting /account" do
    user = create_user(email: "deactivated@example.com", password: "password", verified: true, status: :active)

    sign_in_as(user, password: "password")

    # Ensure we really have a persisted session tied to this user
    assert_equal 1, user.sessions.count, "Expected user to have exactly 1 active session after sign-in"

    # Deactivate after sign-in (simulates deactivation by user or admin)
    user.update!(status: :deactivated)

    # Visiting a gated page should destroy the active session and redirect to sign-in.
    # We assert the user's sessions drop rather than global Session.count, to avoid
    # interference if other tests run in the same process.
    assert_difference -> { user.sessions.reload.count }, -1 do
      get account_overview_path
    end

    assert_response :redirect
    assert_redirected_to new_session_path
  end
end

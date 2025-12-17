# test/integration/account_access_test.rb
#
# These tests protect the governance-critical access rules:
# - email verification gates "active" actions
# - non-active accounts are forcibly logged out
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

    if verified
      user.update!(email_verified_at: Time.current)
    end

    user
  end

  def sign_in_as(user, password:)
    post session_path, params: {
      email_address: user.email_address,
      password: password
    }
  end

  test "unverified signed-in user is blocked from /account (redirects to /activate)" do
    user = create_user(email: "unverified@example.com", password: "password", verified: false)

    assert_difference "Session.count", +1 do
      sign_in_as(user, password: "password")
    end

    assert_no_difference "Session.count" do
      get account_overview_path
    end

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

    assert_difference "Session.count", +1 do
      sign_in_as(user, password: "password")
    end

    # Deactivate after sign-in (simulates an account being deactivated by the user or admin)
    user.update!(status: :deactivated)

    # Visiting a gated page should destroy the active session and redirect to sign-in
    assert_difference "Session.count", -1 do
      get account_overview_path
    end

    assert_redirected_to new_session_path
  end
end

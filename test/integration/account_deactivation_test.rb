# test/integration/account_deactivation_test.rb
#
# Protects the governance promise:
# - deactivation is immediate
# - user is logged out right away
# - gated pages become inaccessible
#
require "test_helper"

class AccountDeactivationTest < ActionDispatch::IntegrationTest
  def create_user(email:, password:, verified: true, status: :active)
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
    post session_path, params: {
      email_address: user.email_address,
      password: password
    }
  end

  test "deactivate account sets status, destroys session, and blocks /account" do
    user = create_user(email: "deactivate_me@example.com", password: "password", verified: true, status: :active)

    assert_difference "Session.count", +1 do
      sign_in_as(user, password: "password")
    end

    assert user.reload.active?

    # Deactivate should:
    # - set status to deactivated
    # - force logout (destroy Session record)
    assert_difference "Session.count", -1 do
      post account_deactivate_path
    end

    assert_redirected_to new_session_path
    assert user.reload.deactivated?

    # Now the user should be treated as signed out + blocked from account area
    get account_overview_path
    assert_redirected_to new_session_path
  end
end

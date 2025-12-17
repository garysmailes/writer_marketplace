# test/integration/registration_flow_test.rb
#
# Protects the sign-up contract:
# - account can be created immediately
# - session starts immediately
# - verification email is sent immediately
# - user is redirected to /activate
#
require "test_helper"

class RegistrationFlowTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  test "successful sign-up creates user, starts session, sends verification email, and redirects to /activate" do
    assert_difference "User.count", +1 do
      assert_difference "Session.count", +1 do
        assert_enqueued_emails 1 do
          post sign_up_path, params: {
            user: {
              email_address: "new_user@example.com",
              password: "password",
              password_confirmation: "password"
            }
          }
        end
      end
    end

    assert_redirected_to activate_path

    user = User.find_by(email_address: "new_user@example.com")
    assert_not_nil user
    assert_not user.verified_email?, "Expected user to start unverified"
    assert user.active?, "Expected new user to be active by default"
  end

  test "invalid sign-up does not create user, does not start session, does not send email" do
    assert_no_difference "User.count" do
      assert_no_difference "Session.count" do
        assert_no_enqueued_emails do
          post sign_up_path, params: {
            user: {
              email_address: "bad_user@example.com",
              password: "password",
              password_confirmation: "not-the-same"
            }
          }
        end
      end
    end

    assert_response :unprocessable_entity
  end

  test "newly signed-up (unverified) user is blocked from verified-only /account" do
    assert_enqueued_emails 1 do
      post sign_up_path, params: {
        user: {
          email_address: "blocked@example.com",
          password: "password",
          password_confirmation: "password"
        }
      }
    end

    # Still signed in (session started), but unverified -> should be blocked by gate
    get account_overview_path
    assert_redirected_to activate_path
  end

  test "duplicate email cannot sign up twice" do
    User.create!(
      email_address: "dup@example.com",
      password: "password",
      password_confirmation: "password",
      status: :active
    )

    assert_no_difference "User.count" do
      assert_no_enqueued_emails do
        post sign_up_path, params: {
          user: {
            email_address: "dup@example.com",
            password: "password",
            password_confirmation: "password"
          }
        }
      end
    end

    assert_response :unprocessable_entity
  end
end

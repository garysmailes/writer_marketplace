# test/integration/email_verification_flow_test.rb
#
# Protects the email verification system:
# - valid token verifies and clears token material
# - invalid/expired tokens do not verify
# - resend verification is authenticated and only sends for unverified users
#
require "test_helper"

class EmailVerificationFlowTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

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
    post session_path, params: {
      email_address: user.email_address,
      password: password
    }
    assert_response :redirect
  end

  test "GET /verify_email/:token verifies user and clears token material" do
    user  = create_user(email: "verify_ok@example.com", password: "password", verified: false)
    token = user.generate_email_verification_token!

    get verify_email_path(token)

    assert_response :redirect
    assert_redirected_to root_path

    user.reload
    assert user.verified_email?, "Expected user to be verified"
    assert_not_nil user.email_verified_at

    assert_nil user.verification_token_digest, "Expected token digest to be cleared"
    assert_nil user.verification_sent_at, "Expected token sent timestamp to be cleared"
  end

  test "GET /verify_email/:token with invalid token does not verify" do
    user = create_user(email: "verify_invalid@example.com", password: "password", verified: false)
    user.generate_email_verification_token!

    get verify_email_path("definitely-not-a-real-token")

    assert_response :redirect
    assert_redirected_to new_session_path

    user.reload
    assert_not user.verified_email?, "Expected user to remain unverified"
  end

  test "GET /verify_email/:token with expired token does not verify" do
    user  = create_user(email: "verify_expired@example.com", password: "password", verified: false)
    token = user.generate_email_verification_token!

    user.update!(verification_sent_at: 3.days.ago)

    get verify_email_path(token)

    assert_response :redirect
    assert_redirected_to new_session_path

    user.reload
    assert_not user.verified_email?, "Expected user to remain unverified"
  end

  test "POST /email_verification/resend requires authentication" do
    user = create_user(email: "resend_requires_auth@example.com", password: "password", verified: false)
    user.generate_email_verification_token!

    assert_no_enqueued_emails do
      post resend_email_verification_path
    end

    assert_response :redirect
    assert_redirected_to new_session_path

    user.reload
    assert_not user.verified_email?
  end

  test "POST /email_verification/resend enqueues an email for unverified signed-in user" do
    user = create_user(email: "resend_ok@example.com", password: "password", verified: false)
    sign_in_as(user, password: "password")

    assert_enqueued_emails 1 do
      post resend_email_verification_path
    end

    assert_response :redirect
    assert_redirected_to root_path
  end

  test "POST /email_verification/resend does not enqueue email when already verified" do
    user = create_user(email: "resend_verified@example.com", password: "password", verified: true)
    sign_in_as(user, password: "password")

    assert_no_enqueued_emails do
      post resend_email_verification_path
    end

    assert_response :redirect
    assert_redirected_to root_path
  end
end

# app/mailers/email_verification_mailer.rb
#
# Sends the "Please verify your email to activate your account" email.
class EmailVerificationMailer < ApplicationMailer
  def verify_email
    @user  = params[:user]
    @token = params[:token]

    mail(
      to: @user.email_address,
      subject: "Please verify your email to activate your account"
    )
  end
end

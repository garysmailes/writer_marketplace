# app/mailers/account_mailer.rb
class AccountMailer < ApplicationMailer
  def reactivation_email(user)
    @user  = user
    @token = @user.signed_id(purpose: :reactivation, expires_in: 2.hours)

    mail to: @user.email_address, subject: "Reactivate your account"
  end
end

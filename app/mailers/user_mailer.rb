class UserMailer < ApplicationMailer
  def otp_code(user, code)
    @user = user
    @code = code

    mail(to: @user.email, subject: "Your sewaLink verification code")
  end
end

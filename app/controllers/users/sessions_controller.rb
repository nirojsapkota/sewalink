class Users::SessionsController < Devise::SessionsController
  def create
    if params[:login_method] == 'phone'
      phone = params[:user][:phone]
      @user = User.find_or_initialize_by(phone: phone)
      
      if @user.new_record?
        # Set a random password for new users registered via phone
        @user.password = Devise.friendly_token[0, 20]
        unless @user.save
          flash[:alert] = @user.errors.full_messages.join(", ")
          return render :new
        end
      end
      
      # Generate and send OTP
      code = @user.current_otp
      @user.send_two_factor_authentication_code(code)
      
      session[:otp_phone] = phone
      redirect_to users_otp_path, notice: t('auth.otp_sent')
    else
      super
    end
  end

  def otp
    @phone = session[:otp_phone]
    if @phone.blank?
      redirect_to new_user_session_path
    else
      if Rails.env.development? || Rails.env.test?
        @user = User.find_by(phone: @phone)
        @dev_otp = @user&.current_otp
      end
    end
  end

  def verify_otp
    @phone = session[:otp_phone]
    @user = User.find_by(phone: @phone)
    
    if @user && @user.validate_and_consume_otp!(params[:otp])
      sign_in(@user)
      session.delete(:otp_phone)
      redirect_to root_path, notice: t('devise.sessions.signed_in')
    else
      flash.now[:alert] = t('devise.two_factor_authentication.invalid_otp') || "Invalid OTP"
      render :otp
    end
  end
end

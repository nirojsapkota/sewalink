class User < ApplicationRecord
  devise :two_factor_authenticatable,
         :registerable,
         :recoverable, :rememberable, :validatable,
         otp_secret_encryption_key: ENV['OTP_SECRET_ENCRYPTION_KEY'] || 'fallback_key_at_least_32_bytes_long_!!!'

  has_one_time_password(column_name: :otp_secret, length: 6)

  enum active_role: { poster: 0, tasker: 1 }

  validates :phone, presence: true, uniqueness: true, format: { with: /\A9[678]\d{8}\z/ }

  def send_two_factor_authentication_code(code)
    SmsService.send_otp(phone, code)
  end

  def email_required?
    false
  end

  def email_changed?
    false
  end

  def will_save_change_to_email?
    false
  end
end

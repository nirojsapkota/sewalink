class User < ApplicationRecord
  devise :two_factor_authenticatable,
         :registerable,
         :recoverable, :rememberable, :validatable,
         otp_secret_encryption_key: ENV['OTP_SECRET_ENCRYPTION_KEY'] || 'fallback_key_at_least_32_bytes_long_!!!'

  enum active_role: { poster: 0, tasker: 1 }

  has_one_attached :avatar
  has_many :tasks, dependent: :destroy
  has_many :bids, dependent: :destroy
  has_many :received_reviews, class_name: 'Review', foreign_key: 'reviewee_id', dependent: :destroy
  has_many :given_reviews, class_name: 'Review', foreign_key: 'reviewer_id', dependent: :destroy

  validates :phone, presence: true, uniqueness: true, format: { with: /\A9[678]\d{8}\z/ }

  def send_two_factor_authentication_code(code)
    SmsService.send_otp(phone, code)
  end

  # Ensure otp_secret is generated if not present
  before_create :generate_otp_secret

  def generate_otp_secret
    self.otp_secret = User.generate_otp_secret if otp_secret.blank?
  end

  def current_otp
    ROTP::TOTP.new(otp_secret, digits: 6).now
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

  def balance
    DoubleEntry.account(:tasker_balance, scope: self).balance
  rescue DoubleEntry::UnknownAccount
    Money.new(0, 'NPR')
  end

  def can_bid?
    balance >= Money.new(-500_00, 'NPR') # -500 NPR threshold
  end
end

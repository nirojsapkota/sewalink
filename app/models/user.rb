class User < ApplicationRecord
  devise :two_factor_authenticatable,
         :registerable,
         :recoverable, :rememberable, :validatable

  enum active_role: { poster: 0, tasker: 1 }

  validates :phone, presence: true, uniqueness: true, format: { with: /\A9[678]\d{8}\z/ }

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

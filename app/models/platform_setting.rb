class PlatformSetting < ApplicationRecord
  DEFAULT_COMMISSION_RATE = BigDecimal("0.10")

  validates :key, presence: true, uniqueness: true

  def self.commission_rate
    value = find_by(key: "commission_rate")&.value
    value.present? ? BigDecimal(value) : DEFAULT_COMMISSION_RATE
  end

  def self.set_commission_rate(rate)
    setting = find_or_initialize_by(key: "commission_rate")
    setting.value = BigDecimal(rate.to_s).to_s
    setting.save!
    setting
  end
end

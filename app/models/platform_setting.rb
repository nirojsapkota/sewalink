class PlatformSetting < ApplicationRecord
  DEFAULT_COMMISSION_RATE = BigDecimal("0.10")
  GEOFENCE_CHECK_IN_KEY = "geofence_check_in_enabled"

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

  # Global toggle for whether on-site tasks require a geofenced (location
  # verified) check-in and completion. Defaults to enabled; when disabled,
  # taskers can start/complete on-site tasks without granting location
  # access, e.g. for demos or regions where GPS is unreliable.
  def self.geofence_check_in_enabled?
    value = find_by(key: GEOFENCE_CHECK_IN_KEY)&.value
    value.nil? ? true : ActiveModel::Type::Boolean.new.cast(value)
  end

  def self.set_geofence_check_in_enabled(enabled)
    setting = find_or_initialize_by(key: GEOFENCE_CHECK_IN_KEY)
    setting.value = ActiveModel::Type::Boolean.new.cast(enabled).to_s
    setting.save!
    setting
  end
end

require 'rails_helper'

RSpec.describe PlatformSetting, type: :model do
  describe '.commission_rate' do
    it 'returns the default rate when no row exists' do
      expect(PlatformSetting.commission_rate).to eq(BigDecimal("0.10"))
    end
  end

  describe '.set_commission_rate' do
    it 'persists the rate and returns it via .commission_rate' do
      PlatformSetting.set_commission_rate(0.15)
      expect(PlatformSetting.commission_rate).to eq(BigDecimal("0.15"))
    end
  end

  describe '.geofence_check_in_enabled?' do
    it 'defaults to true when no row exists' do
      expect(PlatformSetting.geofence_check_in_enabled?).to be true
    end
  end

  describe '.set_geofence_check_in_enabled' do
    it 'persists false and returns it via .geofence_check_in_enabled?' do
      PlatformSetting.set_geofence_check_in_enabled(false)
      expect(PlatformSetting.geofence_check_in_enabled?).to be false
    end

    it 'persists true and returns it via .geofence_check_in_enabled?' do
      PlatformSetting.set_geofence_check_in_enabled(false)
      PlatformSetting.set_geofence_check_in_enabled(true)
      expect(PlatformSetting.geofence_check_in_enabled?).to be true
    end
  end
end

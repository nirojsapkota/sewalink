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
end

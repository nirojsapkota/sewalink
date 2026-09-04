require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'suspension' do
    let(:user) { create(:user) }

    it 'is not suspended by default' do
      expect(user.suspended?).to eq(false)
    end

    it 'is suspended after #suspend!' do
      user.suspend!("reason")
      expect(user.suspended?).to eq(true)
      expect(user.suspension_reason).to eq("reason")
    end

    it 'is not suspended after #reactivate!' do
      user.suspend!("reason")
      user.reactivate!
      expect(user.suspended?).to eq(false)
      expect(user.suspension_reason).to be_nil
    end
  end
end

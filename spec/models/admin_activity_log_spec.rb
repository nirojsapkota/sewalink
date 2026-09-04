require 'rails_helper'

RSpec.describe AdminActivityLog, type: :model do
  describe '.record!' do
    it 'creates a log row attributing the action to the admin and target' do
      admin = create(:user, :admin)
      user = create(:user)

      log = AdminActivityLog.record!(admin: admin, action: "suspend_user", target: user, details: { reason: "abuse" })

      expect(log.admin_id).to eq(admin.id)
      expect(log.action).to eq("suspend_user")
      expect(log.target_type).to eq("User")
      expect(log.target_id).to eq(user.id)
    end
  end
end

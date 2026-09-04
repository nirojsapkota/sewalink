require "rails_helper"

RSpec.describe "Admin::Settings", type: :request do
  let(:admin) { create(:user, :admin) }

  before { sign_in admin }

  describe "GET /admin/settings" do
    it "returns http success and assigns financial overview data" do
      get admin_settings_path

      expect(response).to have_http_status(:success)
      expect(controller.instance_variable_get(:@commission_rate)).to eq(PlatformSetting::DEFAULT_COMMISSION_RATE)
      expect(controller.instance_variable_get(:@platform_revenue_balance)).to be_present
      expect(controller.instance_variable_get(:@total_escrow_held)).to be_present
    end
  end

  describe "PATCH /admin/settings" do
    context "with a valid commission rate" do
      it "updates the PlatformSetting and logs the admin action" do
        patch admin_settings_path, params: { commission_rate: "0.15" }

        expect(PlatformSetting.commission_rate).to eq(BigDecimal("0.15"))
        expect(response).to redirect_to(admin_settings_path)

        log = AdminActivityLog.last
        expect(log.admin).to eq(admin)
        expect(log.action).to eq("update_commission_rate")
      end
    end

    context "with an out-of-range commission rate" do
      it "does not update the setting and redirects with an alert" do
        patch admin_settings_path, params: { commission_rate: "1.5" }

        expect(PlatformSetting.commission_rate).to eq(PlatformSetting::DEFAULT_COMMISSION_RATE)
        expect(response).to redirect_to(admin_settings_path)
        follow_redirect!
        expect(response.body).to include("valid commission rate between 0 and 1")
      end
    end
  end
end

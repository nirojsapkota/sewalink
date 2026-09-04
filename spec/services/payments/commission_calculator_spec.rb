require "rails_helper"

RSpec.describe Payments::CommissionCalculator do
  describe ".call" do
    let(:budget) { Money.new(100000, "NPR") } # रू 1,000.00
    subject { described_class.call(budget) }

    it "calculates correct commission (10%)" do
      expect(subject[:commission]).to eq(Money.new(10000, "NPR")) # रू 100.00
    end

    it "calculates correct tasker share (90%)" do
      expect(subject[:tasker_share]).to eq(Money.new(90000, "NPR")) # रू 900.00
    end

    it "ensures total equals tasker_share + commission" do
      expect(subject[:total]).to eq(budget)
      expect(subject[:total]).to eq(subject[:tasker_share] + subject[:commission])
    end

    context "with rounding" do
      let(:budget) { Money.new(999, "NPR") } # रू 9.99

      it "handles rounding correctly to match the total" do
        # 10% of 9.99 is 0.999. With ROUND_HALF_UP:
        # Commission: 1.00
        # Tasker: 8.99
        # Total: 9.99
        expect(subject[:commission]).to eq(Money.new(100, "NPR"))
        expect(subject[:tasker_share]).to eq(Money.new(899, "NPR"))
        expect(subject[:total]).to eq(budget)
      end
    end

    context "with no PlatformSetting row" do
      it "defaults to the 10% commission rate" do
        expect(subject[:commission]).to eq(Money.new(10000, "NPR"))
      end
    end

    context "when PlatformSetting.commission_rate has been changed" do
      before { PlatformSetting.set_commission_rate(0.20) }

      it "uses the configured rate instead of the default" do
        expect(subject[:commission]).to eq(Money.new(20000, "NPR"))
        expect(subject[:tasker_share]).to eq(Money.new(80000, "NPR"))
      end
    end
  end
end

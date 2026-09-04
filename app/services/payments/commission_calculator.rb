module Payments
  class CommissionCalculator
    def self.call(budget)
      new(budget).call
    end

    def initialize(budget)
      @budget = budget
    end

    def call
      rate = PlatformSetting.commission_rate
      commission = @budget * rate
      tasker_share = @budget - commission

      {
        total: @budget,
        commission: commission,
        tasker_share: tasker_share
      }
    end
  end
end

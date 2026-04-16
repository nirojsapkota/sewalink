module Payments
  class CommissionCalculator
    COMMISSION_PERCENTAGE = 0.10 # 10%

    def self.call(budget)
      new(budget).call
    end

    def initialize(budget)
      @budget = budget
    end

    def call
      commission = @budget * COMMISSION_PERCENTAGE
      tasker_share = @budget - commission

      {
        total: @budget,
        commission: commission,
        tasker_share: tasker_share
      }
    end
  end
end

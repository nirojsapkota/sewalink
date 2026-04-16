module Payments
  class LedgerManager
    class << self
      def deposit_to_escrow(task)
        return if escrow_balance(task) > 0

        DoubleEntry.transfer(
          task.budget,
          from: DoubleEntry.account(:user_external),
          to: DoubleEntry.account(:escrow, scope: task),
          code: :deposit
        )
      end

      def release_from_escrow(task)
        return if escrow_balance(task) == 0

        commission_data = CommissionCalculator.call(task.budget)
        tasker = task.tasker

        # Transfer Tasker's share
        DoubleEntry.transfer(
          commission_data[:tasker_share],
          from: DoubleEntry.account(:escrow, scope: task),
          to: DoubleEntry.account(:tasker_balance, scope: tasker),
          code: :payout
        )

        # Transfer Commission
        DoubleEntry.transfer(
          commission_data[:commission],
          from: DoubleEntry.account(:escrow, scope: task),
          to: DoubleEntry.account(:platform_revenue),
          code: :commission
        )
      end

      def record_cash_commission(task)
        commission_data = CommissionCalculator.call(task.budget)
        tasker = task.tasker

        # Moving from tasker_balance to platform_revenue (even if it makes it negative)
        DoubleEntry.transfer(
          commission_data[:commission],
          from: DoubleEntry.account(:tasker_balance, scope: tasker),
          to: DoubleEntry.account(:platform_revenue),
          code: :cash_commission
        )
      end

      def escrow_balance(task)
        DoubleEntry.account(:escrow, scope: task).balance
      rescue DoubleEntry::UnknownAccount
        0
      end
    end
  end
end

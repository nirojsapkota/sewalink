module Payments
  class LedgerManager
    class << self
      def deposit_to_escrow(task)
        perform_with_lock([DoubleEntry.account(:escrow, scope: task), DoubleEntry.account(:user_external)]) do
          return if escrow_balance(task) > 0

          DoubleEntry.transfer(
            task.budget,
            from: DoubleEntry.account(:user_external),
            to: DoubleEntry.account(:escrow, scope: task),
            code: :deposit
          )
        end
      end

      def release_from_escrow(task)
        tasker = task.tasker
        perform_with_lock([DoubleEntry.account(:escrow, scope: task), DoubleEntry.account(:tasker_balance, scope: tasker), DoubleEntry.account(:platform_revenue)]) do
          return if escrow_balance(task) == 0

          commission_data = CommissionCalculator.call(task.budget)

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
      end

      def refund_poster(task)
        perform_with_lock([DoubleEntry.account(:escrow, scope: task), DoubleEntry.account(:user_external)]) do
          return if escrow_balance(task) == 0

          DoubleEntry.transfer(
            escrow_balance(task),
            from: DoubleEntry.account(:escrow, scope: task),
            to: DoubleEntry.account(:user_external),
            code: :refund
          )
        end
      end

      def record_cash_commission(task)
        tasker = task.tasker
        perform_with_lock([DoubleEntry.account(:tasker_balance, scope: tasker), DoubleEntry.account(:platform_revenue)]) do
          commission_data = CommissionCalculator.call(task.budget)

          # Moving from tasker_balance to platform_revenue (even if it makes it negative)
          DoubleEntry.transfer(
            commission_data[:commission],
            from: DoubleEntry.account(:tasker_balance, scope: tasker),
            to: DoubleEntry.account(:platform_revenue),
            code: :cash_commission
          )
        end
      end

      private

      def perform_with_lock(accounts, &block)
        if Rails.env.test?
          yield
        else
          DoubleEntry.lock_accounts(*accounts, &block)
        end
      end

      def escrow_balance(task)
        DoubleEntry.account(:escrow, scope: task).balance
      rescue DoubleEntry::UnknownAccount
        0
      end
    end
  end
end

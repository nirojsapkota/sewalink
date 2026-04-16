Rails.application.reloader.to_prepare do
  DoubleEntry.configure do |config|
    config.define_accounts do |accounts|
      # Account :escrow (scope: Task, positive_only: true)
      accounts.define(
        identifier: :escrow,
        scope_identifier: ->(task) { task.id },
        positive_only: true
      )

      # Account :tasker_balance (scope: User) - can be negative for CoC (debt)
      accounts.define(
        identifier: :tasker_balance,
        scope_identifier: ->(user) { user.id }
      )

      # Account :platform_revenue (positive_only: true)
      accounts.define(identifier: :platform_revenue, positive_only: true)

      # Account :user_external - global source for incoming payments
      accounts.define(identifier: :user_external)
    end

    config.define_transfers do |transfers|
      # Transfer: External -> Escrow (Deposit)
      transfers.define(from: :user_external, to: :escrow, code: :deposit)

      # Transfer: Escrow -> Tasker (Payout)
      transfers.define(from: :escrow, to: :tasker_balance, code: :payout)

      # Transfer: Escrow -> Platform (Commission for digital payments)
      transfers.define(from: :escrow, to: :platform_revenue, code: :commission)

      # Transfer: Tasker -> Platform (Commission for Cash-on-Completion)
      transfers.define(from: :tasker_balance, to: :platform_revenue, code: :cash_commission)

      # Transfer: External -> Tasker (for testing/top-ups)
      transfers.define(from: :user_external, to: :tasker_balance, code: :deposit)

      # Transfer: Tasker -> External (Withdrawals/Payouts)
      transfers.define(from: :tasker_balance, to: :user_external, code: :payout)
    end
  end
end

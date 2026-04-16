Rails.application.reloader.to_prepare do
  DoubleEntry.configure do |config|
    config.define_accounts do |accounts|
      # Account :escrow (scope: Task, positive_only: true)
      accounts.define(
        identifier: :escrow,
        scope_identifier: accounts.active_record_scope_identifier(Task),
        positive_only: true
      )

      # Account :tasker_balance (scope: User) - can be negative for CoC (debt)
      accounts.define(
        identifier: :tasker_balance,
        scope_identifier: accounts.active_record_scope_identifier(User)
      )

      # Account :platform_revenue (positive_only: true)
      accounts.define(identifier: :platform_revenue, positive_only: true)
    end

    config.define_transfers do |transfers|
      # Transfer: Escrow -> Tasker (Payout)
      transfers.define(from: :escrow, to: :tasker_balance, code: :payout)

      # Transfer: Escrow -> Platform (Commission for digital payments)
      transfers.define(from: :escrow, to: :platform_revenue, code: :commission)

      # Transfer: Tasker -> Platform (Commission for Cash-on-Completion)
      transfers.define(from: :tasker_balance, to: :platform_revenue, code: :cash_commission)
    end
  end
end

module AccountingHelper
  def money_from_cents(cents)
    humanized_money_with_symbol(Money.new(cents.to_i, "NPR"))
  end

  def cash_flow_category_label(key)
    Accounting::CashFlowCategorizer.label_for(key)
  end

  def ledger_account_options
    %w[escrow tasker_balance platform_revenue user_external]
  end

  def ledger_code_options
    %w[deposit payout commission refund cash_commission]
  end
end

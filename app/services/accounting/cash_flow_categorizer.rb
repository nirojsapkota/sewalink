module Accounting
  class CashFlowCategorizer
    CATEGORIES = {
      escrow_deposits: { label: "Escrow Deposits", account: "escrow", code: "deposit", sign: :credit },
      escrow_releases: { label: "Escrow Releases (Payouts)", account: "escrow", code: "payout", sign: :debit },
      commission_revenue: { label: "Commission Revenue", account: "platform_revenue", code: "commission", sign: :credit },
      refunds: { label: "Refunds", account: "escrow", code: "refund", sign: :debit },
      cash_on_completion: { label: "Cash-on-Completion Commission", account: "platform_revenue", code: "cash_commission", sign: :credit },
    }.freeze

    def self.keys
      CATEGORIES.keys
    end

    def self.label_for(key)
      CATEGORIES.fetch(key.to_sym).fetch(:label)
    end

    def self.scope_for(key, from: nil, to: nil)
      config = CATEGORIES.fetch(key.to_sym)
      relation = DoubleEntry::Line.where(account: config[:account], code: config[:code].to_s)
      relation = config[:sign] == :credit ? relation.where("amount > 0") : relation.where("amount < 0")
      relation = relation.where(created_at: from..to) if from && to
      relation.order(created_at: :desc)
    end

    def self.summary(from:, to:)
      CATEGORIES.each_with_object({}) do |(key, config), acc|
        relation = scope_for(key, from: from, to: to)
        acc[key] = {
          label: config[:label],
          total_cents: relation.sum(:amount).abs,
          count: relation.count,
        }
      end
    end
  end
end

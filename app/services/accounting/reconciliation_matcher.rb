module Accounting
  class ReconciliationMatcher
    def self.call(settlement)
      candidates = DoubleEntry::Line
                   .where(account: "escrow", code: "deposit")
                   .where(amount: settlement.amount_cents)
                   .where(created_at: settlement.settled_on.beginning_of_day..settlement.settled_on.end_of_day)

      if candidates.count == 1
        settlement.update!(status: "matched", matched_line_id: candidates.first.id)
      else
        settlement.update!(status: "mismatched", matched_line_id: nil)
      end
    end

    def self.call_all(settlements)
      settlements.find_each { |settlement| call(settlement) }
    end
  end
end

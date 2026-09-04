module Accounting
  class LedgerQuery
    def self.call(from: nil, to: nil, account: nil, code: nil, user_id: nil)
      relation = DoubleEntry::Line.order(created_at: :desc)
      relation = relation.where(created_at: from.beginning_of_day..to.end_of_day) if from.present? && to.present?
      relation = relation.where(account: account) if account.present?
      relation = relation.where(code: code) if code.present?
      relation = apply_user_filter(relation, user_id) if user_id.present?
      relation
    end

    def self.apply_user_filter(relation, user_id)
      posted_task_ids = Task.where(user_id: user_id).pluck(:id)
      accepted_task_ids = Task.joins(:accepted_bid).where(bids: { user_id: user_id }).pluck(:id)
      task_ids = (posted_task_ids + accepted_task_ids).uniq.map(&:to_s)
      task_ids = ["-1"] if task_ids.empty?

      relation.where(
        "(account = 'tasker_balance' AND scope = :uid) OR (account = 'escrow' AND scope IN (:task_ids))",
        uid: user_id.to_s, task_ids: task_ids
      )
    end
  end
end

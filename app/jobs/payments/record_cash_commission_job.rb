module Payments
  # See Payments::DepositToEscrowJob for why this runs in a job rather than
  # directly inside the Task `after_commit` callback.
  class RecordCashCommissionJob < ApplicationJob
    queue_as :default

    def perform(task_id)
      task = Task.find_by(id: task_id)
      return unless task

      Payments::LedgerManager.record_cash_commission(task)
    end
  end
end

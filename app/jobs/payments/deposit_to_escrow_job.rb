module Payments
  # Runs escrow ledger operations outside of the originating request's
  # database transaction. DoubleEntry requires its locking transactions to be
  # the outermost transaction on the connection; calling it directly from an
  # `after_commit` callback fails because Rails has not yet decremented the
  # connection's open-transaction count at that point. Deferring to a job
  # gives the operation a fresh connection context where this holds true.
  class DepositToEscrowJob < ApplicationJob
    queue_as :default

    def perform(task_id)
      task = Task.find_by(id: task_id)
      return unless task

      Payments::LedgerManager.deposit_to_escrow(task)
    end
  end
end

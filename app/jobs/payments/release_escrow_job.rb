module Payments
  # See Payments::DepositToEscrowJob for why this runs in a job rather than
  # directly inside the Task `after_commit` callback.
  class ReleaseEscrowJob < ApplicationJob
    queue_as :default

    def perform(task_id)
      task = Task.find_by(id: task_id)
      return unless task

      Payments::LedgerManager.release_from_escrow(task)
    end
  end
end

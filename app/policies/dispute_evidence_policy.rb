class DisputeEvidencePolicy < ApplicationPolicy
  def create?
    return false if user.nil?
    return false unless (record.task.user == user || record.task.tasker == user)
    
    # Per Plan 05-05, disputes are for completed or in-progress tasks
    record.task.completed? || record.task.in_progress? || record.task.dispute? || record.task.pending_payment?
  end

  class Scope < Scope
    def resolve
      scope.all
    end
  end
end

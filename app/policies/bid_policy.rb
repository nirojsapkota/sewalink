class BidPolicy < ApplicationPolicy
  def create?
    user.tasker? && !user.bids.exists?(task_id: record.task_id)
  end

  def update?
    record.user == user && record.pending?
  end

  def destroy?
    record.user == user && record.pending?
  end

  def show?
    record.user == user || record.task.user == user
  end

  def accept?
    record.task.user == user && record.task.open? && record.pending?
  end

  class Scope < Scope
    def resolve
      if user.poster?
        # Poster sees all bids for their own tasks
        scope.joins(:task).where(tasks: { user_id: user.id })
      else
        # Tasker only sees their own bids
        scope.where(user_id: user.id)
      end
    end
  end
end

class ReviewPolicy < ApplicationPolicy
  def create?
    return false if user.nil?
    return false unless (record.task.user == user || record.task.tasker == user)
    return false unless (record.task.completed? || record.task.pending_payment?)

    # One review per reviewer per task.
    !record.task.reviews.exists?(reviewer_id: user.id)
  end

  class Scope < Scope
    def resolve
      scope.all
    end
  end
end

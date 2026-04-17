class ConversationPolicy < ApplicationPolicy
  def show?
    user_is_poster? || user_is_bidder?
  end

  def index?
    true # All users can see their own conversations, scope will handle what is visible
  end

  def archive?
    user_is_poster? && !bidder_is_assigned_tasker?
  end

  class Scope < Scope
    def resolve
      if user.poster?
        # Poster can see all conversations related to their tasks
        scope.joins(task: :user).where(tasks: { user_id: user.id })
      elsif user.tasker?
        # Tasker can see conversations where they are the bidder
        scope.joins(:bid).where(bids: { user_id: user.id })
      else
        scope.none
      end
    end
  end

  private

  def user_is_poster?
    record.task.user == user
  end

  def user_is_bidder?
    record.bid.user == user
  end

  def bidder_is_assigned_tasker?
    record.bid.user == record.task.tasker
  end
end

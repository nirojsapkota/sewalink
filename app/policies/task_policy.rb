class TaskPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def create?
    user.poster?
  end

  def new?
    create?
  end

  def update?
    record.user == user
  end

  def start?
    record.tasker == user && record.assigned?
  end

  def request_payment?
    record.tasker == user && record.in_progress? && record.esewa?
  end

  def release_payment?
    record.user == user && record.pending_payment?
  end

  def raise_dispute?
    (record.user == user || record.tasker == user) &&
      [:open, :assigned, :in_progress, :pending_payment, :payment_completed].include?(record.status.to_sym)
  end

  def toggle_draft?
    record.user == user && (record.draft? || record.open?)
  end

  def check_geofence?
    record.tasker == user
  end

  def check_in?
    record.tasker == user && record.assigned?
  end

  def complete?
    return false unless record.tasker == user
    
    if record.cash?
      record.in_progress?
    else
      record.payment_completed?
    end
  end

  def edit?
    update?
  end

  def destroy?
    record.user == user
  end

  class Scope < Scope
    def resolve
      scope.all
    end
  end
end

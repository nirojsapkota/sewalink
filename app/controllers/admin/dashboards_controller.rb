class Admin::DashboardsController < Admin::BaseController
  def show
    @new_users_by_day = User.group_by_day(:created_at, last: 30).count
    @tasks_completed_by_day = Task.completed.group_by_day(:completed_at, last: 30).count
    @daily_gmv = Task.completed.group_by_day(:completed_at, last: 30).sum("budget_cents / 100.0")
  end
end

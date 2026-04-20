class Admin::UsersController < Admin::BaseController
  def index
    @users = User.order(created_at: :desc)
    if params[:query].present?
      @users = @users.where("phone LIKE ?", "%#{params[:query]}%")
    end
    @users = @users.page(params[:page]).per(20)
  end

  def show
    @user = User.find(params[:id])
    @tasks_posted = @user.tasks.count
    @tasks_completed_as_tasker = Task.joins(:accepted_bid).where(bids: { user_id: @user.id }).where(status: :completed).count
    @tasks_completed_as_poster = @user.tasks.completed.count
  end
end

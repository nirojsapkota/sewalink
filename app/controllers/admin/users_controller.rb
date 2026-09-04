class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: [:show, :edit, :update, :suspend, :reactivate, :change_role]

  def index
    @users = User.order(created_at: :desc)
    if params[:query].present?
      @users = @users.where("phone LIKE ?", "%#{params[:query]}%")
    end
    @users = @users.page(params[:page]).per(20)
  end

  def show
    @tasks_posted = @user.tasks.count
    @tasks_completed_as_tasker = Task.joins(:accepted_bid).where(bids: { user_id: @user.id }).where(status: :completed).count
    @tasks_completed_as_poster = @user.tasks.completed.count
  end

  def edit
  end

  def update
    if @user.update(user_params)
      log_admin_action!("update_user", @user, details: { changes: user_params.to_h })
      redirect_to admin_user_path(@user), notice: "User updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def suspend
    if @user == current_user
      redirect_to admin_user_path(@user), alert: "You cannot suspend your own account." and return
    end

    @user.suspend!(params[:suspension_reason].presence || "No reason provided")
    log_admin_action!("suspend_user", @user, details: { reason: @user.suspension_reason })
    redirect_to admin_user_path(@user), notice: "User suspended."
  end

  def reactivate
    @user.reactivate!
    log_admin_action!("reactivate_user", @user)
    redirect_to admin_user_path(@user), notice: "User reactivated."
  end

  def change_role
    if @user == current_user
      redirect_to admin_user_path(@user), alert: "You cannot change your own admin access." and return
    end

    new_admin_value = ActiveModel::Type::Boolean.new.cast(params[:admin])
    previous_admin_value = @user.admin?

    if @user.update(admin: new_admin_value)
      log_admin_action!("change_admin_role", @user, details: { from: previous_admin_value, to: new_admin_value })
      redirect_to admin_user_path(@user), notice: new_admin_value ? "Admin access granted." : "Admin access revoked."
    else
      redirect_to admin_user_path(@user), alert: "Failed to change admin access: #{@user.errors.full_messages.join(', ')}"
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:first_name, :last_name, :bio, :locale, :active_role)
  end
end

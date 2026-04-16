class ProfilesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user

  def show
  end

  def edit
  end

  def update
    if @user.update(user_params)
      redirect_to profile_path, notice: t('.success')
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def toggle_role
    new_role = @user.poster? ? 'tasker' : 'poster'
    if @user.update(active_role: new_role)
      redirect_back fallback_location: root_path, notice: t('profiles.roles.toggle', role: t("profiles.roles.#{new_role}"))
    else
      redirect_back fallback_location: root_path, alert: t('.failure')
    end
  end

  private

  def set_user
    @user = current_user
  end

  def user_params
    params.require(:user).permit(:name, :bio, :avatar, :locale)
  end
end

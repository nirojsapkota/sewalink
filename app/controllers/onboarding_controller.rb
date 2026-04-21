class OnboardingController < ApplicationController
  before_action :authenticate_user!
  before_action :redirect_if_onboarded

  def show
    @user = current_user
    @step = (params[:step] || 1).to_i
  end

  def update
    @user = current_user
    @step = (params[:step] || 1).to_i

    if @user.update(user_params)
      if @step < 3
        redirect_to onboarding_path(step: @step + 1)
      else
        @user.update(onboarded: true)
        redirect_to root_path, notice: t('.success')
      end
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:first_name, :last_name, :locale, :active_role)
  end

  def redirect_if_onboarded
    redirect_to root_path if current_user.onboarded?
  end
end

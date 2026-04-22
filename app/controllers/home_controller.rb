class HomeController < ApplicationController
  layout 'landing', only: [:index]
  
  def index
    if user_signed_in?
      if current_user.poster?
        redirect_to poster_dashboard_path
      else
        redirect_to tasker_dashboard_path
      end
    end
  end
end

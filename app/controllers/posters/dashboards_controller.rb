module Posters
  class DashboardsController < ApplicationController
    before_action :authenticate_user!
    before_action :ensure_poster

    def show
      @tasks = current_user.tasks.order(created_at: :desc)

      case params[:status]
      when 'draft'
        @tasks = @tasks.draft
      when 'active'
        @tasks = @tasks.where(status: [:open, :assigned, :in_progress])
      when 'pending_payment'
        @tasks = @tasks.pending_payment
      when 'completed'
        @tasks = @tasks.completed
      when 'dispute'
        @tasks = @tasks.dispute
      end

      @tasks = @tasks.page(params[:page]).per(10)
    end

    private

    def ensure_poster
      unless current_user.poster?
        redirect_to root_path, alert: "Access denied. You must be a poster."
      end
    end
  end
end

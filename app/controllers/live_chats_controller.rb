class LiveChatsController < ApplicationController
  before_action :authenticate_user!

  def show
    @task = current_user.tasks.draft.last
  end
end

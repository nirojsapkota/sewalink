class BidsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_task, only: [:create, :accept]
  before_action :set_bid, only: [:update, :destroy]

  def create
    @bid = @task.bids.build(bid_params)
    @bid.user = current_user
    authorize @bid

    respond_to do |format|
      if @bid.save
        format.html { redirect_to @task, notice: t('.success', default: 'Bid was successfully submitted.') }
        format.turbo_stream
      else
        format.html { render 'tasks/show', status: :unprocessable_entity }
        format.turbo_stream { render turbo_stream: turbo_stream.replace('bid_form', partial: 'bids/form', locals: { task: @task, bid: @bid }) }
      end
    end
  end

  def accept
    @bid = @task.bids.find(params[:id])
    authorize @bid

    ActiveRecord::Base.transaction do
      @bid.update!(status: :accepted)
      @task.update!(status: :assigned)
      @task.bids.where.not(id: @bid.id).update_all(status: :rejected)
    end

    redirect_to @task, notice: t('.success_assign', default: 'Tasker assigned successfully.')
  rescue ActiveRecord::RecordInvalid => e
    redirect_to @task, alert: "Failed to assign tasker: #{e.message}"
  end

  def update
    authorize @bid
    respond_to do |format|
      if @bid.update(bid_params)
        format.html { redirect_to @bid.task, notice: t('.success', default: 'Bid was successfully updated.') }
        format.turbo_stream
      else
        format.html { render 'tasks/show', status: :unprocessable_entity }
        format.turbo_stream { render turbo_stream: turbo_stream.replace('bid_form', partial: 'bids/form', locals: { task: @bid.task, bid: @bid }) }
      end
    end
  end

  def destroy
    authorize @bid
    task = @bid.task
    @bid.destroy
    respond_to do |format|
      format.html { redirect_to task, notice: t('.success', default: 'Bid was successfully removed.') }
      format.turbo_stream
    end
  end

  private

  def set_task
    @task = Task.find(params[:task_id])
  end

  def set_bid
    @bid = Bid.find(params[:id])
  end

  def bid_params
    params.require(:bid).permit(:amount, :message)
  end
end

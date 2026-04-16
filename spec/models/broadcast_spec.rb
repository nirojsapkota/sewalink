require 'rails_helper'

RSpec.describe "Model Broadcasts", type: :model do
  let(:category) { create(:category) }
  let(:poster) { create(:user, active_role: :poster) }
  let(:tasker) { create(:user, active_role: :tasker) }
  let(:task) { create(:task, user: poster, category: category, budget: Money.new(1000_00, "NPR"), payment_type: :esewa, status: :open) }

  before do
    allow(ActionCable.server).to receive(:broadcast)
  end

  it "broadcasts a notification toast to poster when a bid is created" do
    create(:bid, task: task, user: tasker, amount: 900, message: "I can do it")
    
    expect(ActionCable.server).to have_received(:broadcast).with(
      anything,
      /action="prepend" target="notifications"/
    )
  end

  it "broadcasts task replacement when status changes" do
    task.update!(status: :draft)
    
    expect(ActionCable.server).to have_received(:broadcast).with(
      anything,
      /action="replace" target="task_#{task.id}"/
    )
  end

  it "broadcasts a notification toast to tasker when status is changed by poster" do
    # Assign task first to have a tasker
    task.update!(status: :assigned)
    create(:bid, task: task, user: tasker, status: :accepted)
    
    # Clear previous broadcasts
    allow(ActionCable.server).to receive(:broadcast)
    
    task.update!(status: :open)
    
    expect(ActionCable.server).to have_received(:broadcast).with(
      anything,
      /action="prepend" target="notifications"/
    )
  end
end

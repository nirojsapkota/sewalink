require 'rails_helper'

RSpec.describe "Task Escrow Lifecycle", type: :model, use_transactional_fixtures: false do
  # Use non-transactional tests because LedgerManager uses DoubleEntry which requires
  # being the outermost transaction for locking.
  
  before(:each) do
    # Manual cleanup for non-transactional tests
    PaymentTransaction.destroy_all
    Bid.destroy_all
    Task.destroy_all
    User.destroy_all
    Category.destroy_all
    # Clean DoubleEntry tables if possible, or just let it grow during tests
  end

  let(:poster) { create(:user) }
  let(:tasker) { create(:user) }
  let(:category) { create(:category) }
  let(:task) { create(:task, user: poster, category: category, budget: Money.new(1000_00, "NPR"), payment_type: :esewa) }
  let!(:bid) { create(:bid, task: task, user: tasker, amount: Money.new(1000_00, "NPR"), status: :accepted) }

  before do
    task.update!(status: :assigned)
  end

  it "automatically deposits to escrow when payment is completed" do
    payment = create(:payment_transaction, task: task, amount: task.budget, status: :pending)
    expect {
      payment.update!(status: :completed)
    }.to change { DoubleEntry.account(:escrow, scope: task).balance.cents }.from(0).to(1000_00)
  end

  it "requires payment before moving to in_progress for eSewa tasks" do
    expect {
      task.update(status: :in_progress)
    }.not_to change { task.reload.status }
    
    expect(task.errors[:status]).to include("cannot be changed to in_progress or completed without a verified payment for eSewa tasks.")
  end

  it "allows moving to in_progress after payment" do
    payment = create(:payment_transaction, task: task, amount: task.budget, status: :pending)
    payment.update!(status: :completed)
    
    expect {
      task.update!(status: :in_progress)
    }.to change { task.reload.status }.from("assigned").to("in_progress")
  end

  it "automatically releases escrow when task is completed" do
    payment = create(:payment_transaction, task: task, amount: task.budget, status: :pending)
    payment.update!(status: :completed)
    task.update!(status: :in_progress)
    
    commission_data = Payments::CommissionCalculator.call(task.budget)
    
    expect {
      task.update!(status: :completed)
    }.to change { DoubleEntry.account(:escrow, scope: task).balance.cents }.from(1000_00).to(0)
     .and change { DoubleEntry.account(:tasker_balance, scope: tasker).balance.cents }.by(commission_data[:tasker_share].cents)
     .and change { DoubleEntry.account(:platform_revenue).balance.cents }.by(commission_data[:commission].cents)
  end
end

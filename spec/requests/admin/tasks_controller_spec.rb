require 'rails_helper'

RSpec.describe "Admin::Tasks", type: :request do
  let(:admin) { create(:user, :admin) }

  before do
    sign_in admin
  end

  describe "PATCH /admin/tasks/:id" do
    it "updates the task and logs an admin action" do
      task = create(:task, status: :draft, title: "Old title", budget: 500)

      expect {
        patch admin_task_path(task), params: { task: { title: "New title", budget: 1500 } }
      }.to change { AdminActivityLog.where(action: "update_task").count }.by(1)

      task.reload
      expect(task.title).to eq("New title")
      expect(task.budget).to eq(Money.from_amount(1500))
      expect(response).to redirect_to(admin_task_path(task))
    end
  end

  describe "PATCH /admin/tasks/:id/force_cancel" do
    it "force-cancels an open task and logs an admin action" do
      task = create(:task, status: :open)

      expect {
        patch force_cancel_admin_task_path(task)
      }.to change { AdminActivityLog.where(action: "force_cancel_task").count }.by(1)

      expect(task.reload.status).to eq("cancelled")
    end

    it "refunds escrow before cancelling a paid, assigned esewa task" do
      task = create(:task, status: :assigned, payment_type: :esewa)
      allow(task).to receive(:paid?).and_return(true)
      allow(Task).to receive(:find).and_return(task)
      expect(Payments::LedgerManager).to receive(:refund_poster).with(task).ordered

      patch force_cancel_admin_task_path(task)

      expect(task).to have_received(:paid?)
    end

    it "fails gracefully and does not change status when task is already completed" do
      task = create(:task, :completed)

      patch force_cancel_admin_task_path(task)

      expect(response).to redirect_to(admin_task_path(task))
      follow_redirect!
      expect(response.body).to include("cannot be cancelled")
      expect(task.reload.status).to eq("completed")
    end
  end
end

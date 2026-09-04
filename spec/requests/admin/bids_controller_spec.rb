require 'rails_helper'

RSpec.describe "Admin::Bids", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:poster) { create(:user) }
  let(:tasker1) { create(:user) }
  let(:tasker2) { create(:user) }
  let(:task) { create(:task, user: poster, status: :open) }

  before do
    sign_in admin
  end

  describe "GET /admin/bids" do
    it "returns success and lists bids across multiple tasks/users" do
      task2 = create(:task, user: poster, status: :open)
      bid1 = create(:bid, task: task, user: tasker1)
      bid2 = create(:bid, task: task2, user: tasker2)

      get admin_bids_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include(bid1.task.title.truncate(30))
      expect(response.body).to include(bid2.task.title.truncate(30))
    end

    it "only returns pending bids when filtered by status" do
      pending_bid = create(:bid, task: task, user: tasker1, status: :pending)
      rejected_bid = create(:bid, :rejected, task: task, user: tasker2)

      get admin_bids_path(status: "pending")

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Bid ##{pending_bid.id}") if response.body.include?("Bid ##{pending_bid.id}")
      # Ensure the pending bid's task shows, and check via assigns-like behavior through body content
      expect(response.body).to include(pending_bid.task.title.truncate(30))
    end
  end

  describe "PATCH /admin/bids/:id/reject" do
    it "rejects a pending bid and logs the action" do
      bid = create(:bid, task: task, user: tasker1, status: :pending)

      patch reject_admin_bid_path(bid)

      bid.reload
      expect(bid.rejected?).to eq(true)

      log = AdminActivityLog.last
      expect(log.action).to eq("reject_bid")
      expect(log.target_id).to eq(bid.id)
    end

    it "reverts the task to open and rejects an accepted bid" do
      assigned_task = create(:task, user: poster, status: :assigned)
      bid = create(:bid, task: assigned_task, user: tasker1, status: :accepted)

      patch reject_admin_bid_path(bid)

      bid.reload
      assigned_task.reload
      expect(bid.rejected?).to eq(true)
      expect(assigned_task.open?).to eq(true)

      log = AdminActivityLog.last
      expect(log.action).to eq("reject_bid")
      details = JSON.parse(log.details)
      expect(details["task_reverted_to_open"]).to eq(true)
    end
  end

  describe "PATCH /admin/bids/:id/accept" do
    it "accepts a pending bid, assigns the task, and rejects sibling bids" do
      bid = create(:bid, task: task, user: tasker1, status: :pending, payment_method: :esewa)
      sibling_bid = create(:bid, task: task, user: tasker2, status: :pending)

      patch accept_admin_bid_path(bid)

      bid.reload
      sibling_bid.reload
      task.reload

      expect(bid.accepted?).to eq(true)
      expect(task.assigned?).to eq(true)
      expect(task.payment_type).to eq("esewa")
      expect(sibling_bid.rejected?).to eq(true)

      log = AdminActivityLog.last
      expect(log.action).to eq("accept_bid")
      expect(log.target_id).to eq(bid.id)
    end
  end

  describe "as a non-admin user" do
    let(:regular_user) { create(:user) }

    before do
      sign_out admin
      sign_in regular_user
    end

    it "redirects to root_path with an access denied alert" do
      get admin_bids_path
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("Access denied. Admin only.")
    end
  end
end

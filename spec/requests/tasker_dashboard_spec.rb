require 'rails_helper'

RSpec.describe "TaskerDashboard", type: :request do
  let(:tasker) { create(:user, active_role: :tasker, onboarded: true) }
  let(:poster) { create(:user, active_role: :poster, onboarded: true) }
  let(:category) { create(:category) }

  before { sign_in tasker }

  describe "GET /tasker_dashboard" do
    it "shows each job's real status instead of a hardcoded label" do
      assigned_task = create(:task, user: poster, category: category, status: :assigned)
      create(:bid, task: assigned_task, user: tasker, status: :accepted)

      completed_task = create(:task, user: poster, category: category, status: :completed, completed_at: 1.day.ago)
      create(:bid, task: completed_task, user: tasker, status: :accepted)

      get tasker_dashboard_path

      expect(response.body).to include(I18n.t("tasks.statuses.assigned"))
      expect(response.body).to include(I18n.t("tasks.statuses.completed"))
    end
  end
end

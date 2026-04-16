require "test_helper"

class TaskerDashboardControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get tasker_dashboard_index_url
    assert_response :success
  end
end

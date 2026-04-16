require "test_helper"

class TaskTest < ActiveSupport::TestCase
  def setup
    @user = users(:one) # Assumes fixtures exist from previous phases
    @category = categories(:one)
    @task = Task.new(
      title: "Fix broken tap",
      description: "Water is leaking from the kitchen tap.",
      budget: 500,
      location: "Kathmandu, Nepal",
      status: :open,
      user: @user,
      category: @category
    )
  end

  test "should be valid" do
    assert @task.valid?
  end

  test "title should be present" do
    @task.title = ""
    assert_not @task.valid?
  end

  test "description should be present" do
    @task.description = ""
    assert_not @task.valid?
  end

  test "budget should be present" do
    @task.budget = nil
    assert_not @task.valid?
  end

  test "location should be present" do
    @task.location = ""
    assert_not @task.valid?
  end

  test "category should be present" do
    @task.category = nil
    assert_not @task.valid?
  end

  test "user should be present" do
    @task.user = nil
    assert_not @task.valid?
  end

  test "should have status enum" do
    assert_respond_to @task, :open?
    assert_respond_to @task, :draft?
    assert_respond_to @task, :assigned?
    assert_respond_to @task, :completed?
    assert_respond_to @task, :cancelled?
  end

  test "should geocode location on save" do
    # This might need a mock for geocoder if we don't want real API calls in tests
    @task.save
    assert_not_nil @task.latitude
    assert_not_nil @task.longitude
  end
end

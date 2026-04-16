require "test_helper"

class CategoryTest < ActiveSupport::TestCase
  def setup
    @category = Category.new(name_en: "Plumbing", name_ne: "प्लम्बिङ")
  end

  test "should be valid" do
    assert @category.valid?
  end

  test "name_en should be present" do
    @category.name_en = ""
    assert_not @category.valid?
  end

  test "name_ne should be present" do
    @category.name_ne = ""
    assert_not @category.valid?
  end

  test "name_en should be unique" do
    duplicate_category = @category.dup
    @category.save
    assert_not duplicate_category.valid?
  end

  test "name_ne should be unique" do
    duplicate_category = @category.dup
    @category.save
    assert_not duplicate_category.valid?
  end
end

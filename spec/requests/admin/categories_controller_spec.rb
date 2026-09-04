require 'rails_helper'

RSpec.describe "Admin::Categories", type: :request do
  let(:admin) { create(:user, :admin) }

  before do
    sign_in admin
  end

  describe "POST /admin/categories" do
    it "creates a category with valid params and logs the action" do
      expect {
        post admin_categories_path, params: { category: { name_en: "Plumbing", name_ne: "प्लम्बिङ" } }
      }.to change(Category, :count).by(1)

      expect(response).to redirect_to(admin_categories_path)
      category = Category.find_by(name_en: "Plumbing")
      log = AdminActivityLog.last
      expect(log.action).to eq("create_category")
      expect(log.target_id).to eq(category.id)
    end

    it "re-renders new with 422 on duplicate name_en" do
      existing = create(:category, name_en: "Cleaning")

      expect {
        post admin_categories_path, params: { category: { name_en: existing.name_en, name_ne: "अर्को" } }
      }.not_to change(Category, :count)

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH /admin/categories/:id" do
    it "updates name_en/name_ne/active and logs the action" do
      category = create(:category, active: true)

      patch admin_category_path(category), params: { category: { name_en: "Updated EN", name_ne: "अद्यावधिक", active: false } }

      expect(response).to redirect_to(admin_categories_path)
      category.reload
      expect(category.name_en).to eq("Updated EN")
      expect(category.name_ne).to eq("अद्यावधिक")
      expect(category.active).to eq(false)

      log = AdminActivityLog.last
      expect(log.action).to eq("update_category")
    end
  end

  describe "DELETE /admin/categories/:id" do
    it "destroys a category with zero tasks and logs the action" do
      category = create(:category)

      expect {
        delete admin_category_path(category)
      }.to change(Category, :count).by(-1)

      expect(response).to redirect_to(admin_categories_path)
      log = AdminActivityLog.last
      expect(log.action).to eq("delete_category")
    end

    it "does not destroy a category referenced by an existing task" do
      category = create(:category)
      user = create(:user)
      create(:task, category: category, user: user)

      expect {
        delete admin_category_path(category)
      }.not_to change(Category, :count)

      expect(response).to redirect_to(admin_categories_path)
      follow_redirect!
      expect(response.body).to include("in use")
      expect(Category.exists?(category.id)).to be true
    end
  end

  describe "PATCH /admin/categories/:id/move_up" do
    it "swaps position with the immediately preceding category" do
      first = create(:category, position: 1)
      second = create(:category, position: 2)

      patch move_up_admin_category_path(second)

      first.reload
      second.reload
      expect(second.position).to eq(1)
      expect(first.position).to eq(2)
    end
  end
end

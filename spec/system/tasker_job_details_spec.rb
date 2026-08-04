require 'rails_helper'

RSpec.describe 'Tasker viewing job details', type: :system do
  let(:poster) { User.create!(first_name: 'Poster', last_name: 'User', phone: '9800000001', active_role: :poster, password: 'password', password_confirmation: 'password') }
  let(:tasker) { User.create!(first_name: 'Tasker', last_name: 'User', phone: '9800000002', active_role: :tasker, password: 'password', password_confirmation: 'password') }
  let(:category) { Category.create!(name_en: 'Cleaning', name_ne: 'सफाई') }
  let(:task) { Task.create!(title: 'Clean house', description: 'Cleaning needed', budget: 1000, location: 'Kathmandu', user: poster, category: category, status: :open) }

  before do
    # Assuming authentication is via Devise
    login_as(tasker, scope: :user)
  end

  it 'allows tasker to view job details without error' do
    visit task_path(task)
    expect(page).to have_content('Clean house')
  end
end

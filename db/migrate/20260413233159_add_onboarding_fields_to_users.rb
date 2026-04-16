class AddOnboardingFieldsToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :name, :string
    add_column :users, :bio, :text
    add_column :users, :locale, :string
    add_column :users, :onboarded, :boolean, default: false, null: false
  end
end

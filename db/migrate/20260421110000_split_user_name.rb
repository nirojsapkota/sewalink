class SplitUserName < ActiveRecord::Migration[7.1]
  def up
    add_column :users, :first_name, :string
    add_column :users, :last_name, :string

    # Migrate data
    User.reset_column_information
    User.find_each do |user|
      if user.name.present?
        parts = user.name.split(' ', 2)
        user.update_columns(first_name: parts[0], last_name: parts[1])
      end
    end

    remove_column :users, :name
  end

  def down
    add_column :users, :name, :string

    # Migrate data back
    User.reset_column_information
    User.find_each do |user|
      full_name = [user.first_name, user.last_name].compact.join(' ')
      user.update_columns(name: full_name)
    end

    remove_column :users, :first_name
    remove_column :users, :last_name
  end
end

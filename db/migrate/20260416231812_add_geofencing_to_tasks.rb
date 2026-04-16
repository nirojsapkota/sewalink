class AddGeofencingToTasks < ActiveRecord::Migration[7.1]
  def change
    add_column :tasks, :on_site, :boolean, default: true, null: false
  end
end

class AddAdminManagementFields < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :suspended_at, :datetime
    add_column :users, :suspension_reason, :string

    add_column :categories, :position, :integer, default: 0, null: false
    add_column :categories, :active, :boolean, default: true, null: false
    add_index :categories, :position

    create_table :platform_settings do |t|
      t.string :key, null: false
      t.string :value
      t.timestamps
    end
    add_index :platform_settings, :key, unique: true

    create_table :admin_activity_logs do |t|
      t.bigint :admin_id, null: false
      t.string :action, null: false
      t.string :target_type
      t.bigint :target_id
      t.text :details
      t.timestamps
    end
    add_index :admin_activity_logs, :admin_id
    add_index :admin_activity_logs, [:target_type, :target_id]
    add_foreign_key :admin_activity_logs, :users, column: :admin_id
  end
end

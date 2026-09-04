class MigrateAdminFlagToSuperAdminRole < ActiveRecord::Migration[7.1]
  def up
    User.where(admin: true).find_each do |user|
      user.add_role(:super_admin) unless user.has_role?(:super_admin)
    end
  end

  def down
    # Intentionally a no-op: do not strip roles on rollback, this would be
    # a destructive, irreversible access-control change.
  end
end

class AddNewStatusesToTasks < ActiveRecord::Migration[7.1]
  def up
    # Statuses remapping to align with the new 9-state enum:
    # Old: { draft: 0, open: 1, assigned: 2, in_progress: 3, completed: 4, cancelled: 5 }
    # New: { draft: 0, open: 1, assigned: 2, in_progress: 3, pending_payment: 4, payment_completed: 5, completed: 6, dispute: 7, cancelled: 8 }

    execute <<-SQL
      UPDATE tasks SET status = 6 WHERE status = 4; -- completed -> completed
      UPDATE tasks SET status = 8 WHERE status = 5; -- cancelled -> cancelled
    SQL
  end

  def down
    execute <<-SQL
      UPDATE tasks SET status = 4 WHERE status = 6;
      UPDATE tasks SET status = 5 WHERE status = 8;
    SQL
  end
end

class RemoveBudgetFromTasks < ActiveRecord::Migration[7.1]
  def change
    remove_column :tasks, :budget, :decimal
  end
end

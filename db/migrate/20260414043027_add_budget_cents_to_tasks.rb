class AddBudgetCentsToTasks < ActiveRecord::Migration[7.1]
  def change
    add_column :tasks, :budget_cents, :integer, default: 0, null: false
    
    # Migrate data
    reversible do |dir|
      dir.up do
        execute "UPDATE tasks SET budget_cents = budget * 100"
      end
    end
    
    # We'll keep the budget column for now to avoid breaking other things, 
    # but we can remove it later.
  end
end

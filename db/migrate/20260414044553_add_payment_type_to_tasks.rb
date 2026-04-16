class AddPaymentTypeToTasks < ActiveRecord::Migration[7.1]
  def change
    add_column :tasks, :payment_type, :integer
  end
end

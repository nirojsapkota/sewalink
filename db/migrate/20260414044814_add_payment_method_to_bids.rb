class AddPaymentMethodToBids < ActiveRecord::Migration[7.1]
  def change
    add_column :bids, :payment_method, :integer
  end
end

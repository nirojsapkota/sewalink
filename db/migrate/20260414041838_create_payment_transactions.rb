class CreatePaymentTransactions < ActiveRecord::Migration[7.1]
  def change
    create_table :payment_transactions do |t|
      t.references :task, null: false, foreign_key: true
      t.integer :amount_cents
      t.string :transaction_uuid, index: { unique: true }
      t.string :status, default: 'pending', null: false
      t.string :external_ref

      t.timestamps
    end
  end
end

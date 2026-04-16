class CreatePayoutRequests < ActiveRecord::Migration[7.1]
  def change
    create_table :payout_requests do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :amount_cents
      t.string :status
      t.text :payment_details
      t.text :rejection_reason

      t.timestamps
    end
  end
end

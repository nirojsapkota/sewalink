class CreateEsewaSettlements < ActiveRecord::Migration[7.1]
  def change
    create_table :esewa_settlements do |t|
      t.string :transaction_ref, null: false
      t.integer :amount_cents, null: false
      t.date :settled_on, null: false
      t.string :status, null: false, default: "unmatched"
      t.text :raw_row
      t.references :imported_by, null: false, foreign_key: { to_table: :users }
      t.integer :matched_line_id
      t.timestamps
    end
    add_index :esewa_settlements, :transaction_ref
    add_index :esewa_settlements, :status
    add_index :esewa_settlements, :settled_on
  end
end

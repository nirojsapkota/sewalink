class CreateBids < ActiveRecord::Migration[7.1]
  def change
    create_table :bids do |t|
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.text :message, null: false
      t.integer :status, default: 0, index: true, null: false
      t.references :user, null: false, foreign_key: true
      t.references :task, null: false, foreign_key: true

      t.timestamps
    end
  end
end

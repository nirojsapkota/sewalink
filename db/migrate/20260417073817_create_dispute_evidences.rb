class CreateDisputeEvidences < ActiveRecord::Migration[7.1]
  def change
    create_table :dispute_evidences do |t|
      t.references :task, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :description

      t.timestamps
    end
  end
end

class CreateTasks < ActiveRecord::Migration[7.1]
  def change
    create_table :tasks do |t|
      t.string :title, null: false
      t.text :description, null: false
      t.decimal :budget, precision: 12, scale: 2, null: false
      t.string :location, null: false
      t.float :latitude
      t.float :longitude
      t.integer :status, default: 0, null: false
      t.references :user, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true

      t.timestamps
    end
  end
end

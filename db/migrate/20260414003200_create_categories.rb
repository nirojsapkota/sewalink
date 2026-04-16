class CreateCategories < ActiveRecord::Migration[7.1]
  def change
    create_table :categories do |t|
      t.string :name_en
      t.string :name_ne

      t.timestamps
    end
    add_index :categories, :name_en
    add_index :categories, :name_ne
  end
end

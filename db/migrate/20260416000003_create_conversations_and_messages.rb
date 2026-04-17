class CreateConversationsAndMessages < ActiveRecord::Migration[7.1]
  def change
    create_table :conversations do |t|
      t.references :bid, null: false, foreign_key: true
      t.references :task, null: false, foreign_key: true
      t.boolean :archived, default: false

      t.timestamps
    end

    create_table :messages do |t|
      t.references :conversation, null: false, foreign_key: true
      t.references :sender, null: false, foreign_key: { to_table: :users }
      t.text :content

      t.timestamps
    end
  end
end

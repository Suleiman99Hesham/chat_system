class CreateMessages < ActiveRecord::Migration[5.2]
  def change
    create_table :messages do |t|
      t.references :chat, foreign_key: true
      t.integer :number
      t.text :body

      t.timestamps
    end
    add_index :messages, :body, length: 255
  end
end

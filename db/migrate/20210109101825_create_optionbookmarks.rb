class CreateOptionbookmarks < ActiveRecord::Migration[6.1]
  def change
    create_table :optionbookmarks do |t|
      t.string :longleg
      t.string :shortleg
      t.integer :user_id

      t.timestamps
    end
    add_index :optionbookmarks, :user_id
  end
end

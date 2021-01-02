class CreateOptionhighopeninterests < ActiveRecord::Migration[6.1]
  def change
    create_table :optionhighopeninterests do |t|
      t.string :underlying
      t.string :expiration_date
      t.float :strike
      t.float :bid
      t.float :ask
      t.float :last_volume
      t.float :open_interest
      t.string :symbol
      t.float :quote
      t.string :description

      t.timestamps
    end
  end
end

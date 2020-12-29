class CreateOptionchains < ActiveRecord::Migration[6.1]
  def change
    create_table :optionchains do |t|
      t.belongs_to :universe, index: true, foreign_key: true
      t.string :symbol
      t.text :description
      t.string :exch
      t.string :option_type
      t.float :volume
      t.float :bid
      t.float :ask
      t.string :underlying
      t.float :strike
      t.float :change_percentage
      t.float :average_volume
      t.float :last_volume
      t.float :bidsize
      t.float :asksize
      t.float :open_interest
      t.float :contract_size
      t.string :expiration_date
      t.string :expiration_type
      t.string :root_symbol
      t.float :bid_iv
      t.float :mid_iv
      t.float :ask_iv

      t.timestamps
    end
  end
end

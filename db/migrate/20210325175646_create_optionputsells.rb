class CreateOptionputsells < ActiveRecord::Migration[6.1]
  def change
    create_table :optionputsells do |t|
      t.string :underlying
      t.string :optionsymbol
      t.float  :strike
      t.float  :quote
      t.float  :bid
      t.float  :ask
      t.float  :premiumratio
      t.string :expiry_date
      t.string :industry
      t.string :company

      t.timestamps
    end
  end
end



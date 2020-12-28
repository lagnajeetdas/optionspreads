class CreateStockprofiles < ActiveRecord::Migration[6.1]
  def change
    create_table :stockprofiles do |t|
      t.string :symbol
      t.text :logo
      t.string :industry
      t.float :marketcap

      t.timestamps
    end
  end
end

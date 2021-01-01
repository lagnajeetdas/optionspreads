class CreateStockprices < ActiveRecord::Migration[6.1]
  def change
    create_table :stockprices do |t|
      t.string :symbol
      t.float :last

      t.timestamps
    end
  end
end

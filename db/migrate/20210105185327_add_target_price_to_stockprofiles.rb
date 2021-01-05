class AddTargetPriceToStockprofiles < ActiveRecord::Migration[6.1]
  def change
    add_column :stockprofiles, :target_price, :float
  end
end

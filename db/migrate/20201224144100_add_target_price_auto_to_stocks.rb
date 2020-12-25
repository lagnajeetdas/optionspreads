class AddTargetPriceAutoToStocks < ActiveRecord::Migration[6.1]
  def change
    add_column :stocks, :target_price_auto, :float
  end
end

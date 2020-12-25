class AddTargetPriceManualToStocks < ActiveRecord::Migration[6.1]
  def change
    add_column :stocks, :target_price_manual, :float
  end
end

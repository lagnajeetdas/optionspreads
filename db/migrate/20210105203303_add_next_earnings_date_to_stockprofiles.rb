class AddNextEarningsDateToStockprofiles < ActiveRecord::Migration[6.1]
  def change
    add_column :stockprofiles, :next_earnings_date, :string
  end
end

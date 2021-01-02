class CreateTopoptionscenarios < ActiveRecord::Migration[6.1]
  def change
    create_table :topoptionscenarios do |t|
      t.string :underlying
      t.string :expiry_date
      t.float :buy_strike
      t.float :sell_strike
      t.float :risk
      t.float :reward
      t.float :rr_ratio
      t.float :perc_change
      t.string :buy_contract_symbol
      t.string :sell_contract_symbol
      t.float :buy_contract_iv
      t.float :sell_contract_iv
      t.float :stock_quote
      t.string :stock_description

      t.timestamps
    end
  end
end

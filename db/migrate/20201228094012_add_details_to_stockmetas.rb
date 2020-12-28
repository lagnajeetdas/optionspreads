class AddDetailsToStockmetas < ActiveRecord::Migration[6.1]
  def change
    add_column :stockmetas, :marketcap_type, :string
    add_column :stockmetas, :belongsto_index, :string
  end
end

class AddDetailsToStockprofiles < ActiveRecord::Migration[6.1]
  def change
    add_column :stockprofiles, :marketcap_type, :string
    add_column :stockprofiles, :belongsto_index, :string
  end
end

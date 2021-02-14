class AddDetailsToUniverses < ActiveRecord::Migration[6.1]
  def change
    add_column :universes, :target_price, :float
  end
end

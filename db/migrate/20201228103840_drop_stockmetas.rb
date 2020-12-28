class DropStockmetas < ActiveRecord::Migration[6.1]
  def change
  	drop_table :stockmetas
  end
end

class AddDetailsToOptionchains < ActiveRecord::Migration[6.1]
  def change
    add_column :optionchains, :quote, :float
  end
end

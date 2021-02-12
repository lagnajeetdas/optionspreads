class AddDetailsToOptionscenarios < ActiveRecord::Migration[6.1]
  def change
    add_column :optionscenarios, :quote, :float
  end
end

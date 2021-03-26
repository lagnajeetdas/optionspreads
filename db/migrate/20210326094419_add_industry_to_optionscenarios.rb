class AddIndustryToOptionscenarios < ActiveRecord::Migration[6.1]
  def change
    add_column :optionscenarios, :industry, :string
  end
end

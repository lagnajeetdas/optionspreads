class AddCompanyToOptionscenarios < ActiveRecord::Migration[6.1]
  def change
    add_column :optionscenarios, :company, :string
  end
end

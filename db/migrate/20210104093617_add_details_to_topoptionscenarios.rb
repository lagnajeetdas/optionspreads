class AddDetailsToTopoptionscenarios < ActiveRecord::Migration[6.1]
  def change
    add_column :topoptionscenarios, :industry, :string
  end
end

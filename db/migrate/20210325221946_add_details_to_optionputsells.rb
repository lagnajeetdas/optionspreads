class AddDetailsToOptionputsells < ActiveRecord::Migration[6.1]
  def change
    add_column :optionputsells, :option_type, :string
  end
end

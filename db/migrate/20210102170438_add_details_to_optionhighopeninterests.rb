class AddDetailsToOptionhighopeninterests < ActiveRecord::Migration[6.1]
  def change
    add_column :optionhighopeninterests, :option_type, :string
  end
end

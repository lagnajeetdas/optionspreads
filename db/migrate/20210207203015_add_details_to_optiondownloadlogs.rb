class AddDetailsToOptiondownloadlogs < ActiveRecord::Migration[6.1]
  def change
    add_column :optiondownloadlogs, :function_name, :string
  end
end

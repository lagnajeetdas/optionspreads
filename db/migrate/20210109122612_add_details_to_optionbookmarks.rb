class AddDetailsToOptionbookmarks < ActiveRecord::Migration[6.1]
  def change
    add_column :optionbookmarks, :underlying, :string
    add_column :optionbookmarks, :e_date, :string
  end
end

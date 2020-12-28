class CreateStockmetas < ActiveRecord::Migration[6.1]
  def change
    create_table :stockmetas do |t|
      t.string :symbol
      t.text :logo
      t.float :marketcap
      t.string :industry

      t.timestamps
    end
  end
end

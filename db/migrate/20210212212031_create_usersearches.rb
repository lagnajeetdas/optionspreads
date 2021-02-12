class CreateUsersearches < ActiveRecord::Migration[6.1]
  def change
    create_table :usersearches do |t|
      t.string :symbol
      t.string :who

      t.timestamps
    end
  end
end

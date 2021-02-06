class CreateExpirycalendars < ActiveRecord::Migration[6.1]
  def change
    create_table :expirycalendars do |t|
      t.string :year
      t.string :expiry_date

      t.timestamps
    end
  end
end

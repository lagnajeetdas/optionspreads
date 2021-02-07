class CreateOptiondownloadlogs < ActiveRecord::Migration[6.1]
  def change
    create_table :optiondownloadlogs do |t|
      t.string :activity
      t.datetime :execution_time
      t.integer :count

      t.timestamps
    end
  end
end

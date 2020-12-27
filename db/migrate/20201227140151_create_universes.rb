class CreateUniverses < ActiveRecord::Migration[6.1]
  def change
    create_table :universes do |t|
      t.string :currency
      t.text :description
      t.string :displaysymbol
      t.text :figi
      t.string :mic
      t.string :type

      t.timestamps
    end
  end
end

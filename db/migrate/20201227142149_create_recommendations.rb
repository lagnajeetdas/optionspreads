class CreateRecommendations < ActiveRecord::Migration[6.1]
  def change
    create_table :recommendations do |t|
      t.float :buy
      t.float :hold
      t.string :period
      t.float :sell
      t.float :strongbuy
      t.float :strongsell
      t.string :symbol

      t.timestamps
    end
  end
end

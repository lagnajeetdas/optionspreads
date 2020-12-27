class RemoveTypeFromUniverses < ActiveRecord::Migration[6.1]
  def change
    remove_column :universes, :type, :string
  end
end

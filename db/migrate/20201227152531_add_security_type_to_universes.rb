class AddSecurityTypeToUniverses < ActiveRecord::Migration[6.1]
  def change
    add_column :universes, :security_type, :string
  end
end

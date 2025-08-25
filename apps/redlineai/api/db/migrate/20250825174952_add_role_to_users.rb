class AddRoleToUsers < ActiveRecord::Migration[8.0]
  def up
    add_column :users, :role, :string, null: false, default: 'user'
    add_index :users, :role

    # Backfill: ensure any existing nulls are set (for safety if schema differs)
    execute <<~SQL
      UPDATE users SET role = 'user' WHERE role IS NULL;
    SQL

    # Promote the very first user to super_admin if present
    execute <<~SQL
      UPDATE users SET role = 'super_admin' WHERE id = 1;
    SQL
  end

  def down
    remove_index :users, :role
    remove_column :users, :role
  end
end

class AddPublicIdToUsers < ActiveRecord::Migration[8.0]
  def up
    add_column :users, :public_id, :string
    
    # Generate public_ids for existing users
    User.find_each do |user|
      user.update_column(:public_id, SecureRandom.urlsafe_base64(12))
    end
    
    # Make the column non-nullable after populating existing records
    change_column_null :users, :public_id, false
    add_index :users, :public_id, unique: true
  end
  
  def down
    remove_index :users, :public_id
    remove_column :users, :public_id
  end
end

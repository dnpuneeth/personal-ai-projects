class CreateReferrals < ActiveRecord::Migration[8.0]
  def change
    create_table :referrals do |t|
      t.references :referrer, null: false, foreign_key: { to_table: :users }
      t.references :referred, null: false, foreign_key: { to_table: :users }
      t.string :code, null: false
      t.string :status, null: false, default: 'pending'
      t.datetime :completed_at

      t.timestamps
    end
    
    add_index :referrals, :code, unique: true
    add_index :referrals, [:referrer_id, :status]
  end
end

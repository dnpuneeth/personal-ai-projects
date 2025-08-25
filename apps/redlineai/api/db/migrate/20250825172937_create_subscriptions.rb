class CreateSubscriptions < ActiveRecord::Migration[8.0]
  def change
    create_table :subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :plan, null: false, default: 'free'
      t.string :status, null: false, default: 'active'
      t.string :stripe_subscription_id
      t.datetime :current_period_start
      t.datetime :current_period_end

      t.timestamps
    end
    
    add_index :subscriptions, :stripe_subscription_id, unique: true
    add_index :subscriptions, [:user_id, :status]
  end
end

class CreateNotificationTargetUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :notification_target_users do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name,  null: false, default: ""
      t.string :email, null: false, default: ""
      t.integer :confirmation_status, default: 0, null: false
      t.string :confirmation_token, limit: 64
      t.datetime :expiration_date

      t.timestamps
    end

    add_index :notification_target_users, [:user_id, :email],  unique: true
    add_index :notification_target_users, :confirmation_token, unique: true
  end
end

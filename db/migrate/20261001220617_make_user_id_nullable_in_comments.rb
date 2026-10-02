class MakeUserIdNullableInComments < ActiveRecord::Migration[8.1]
  def change
      change_column :comments, :user_id, :bigint, null: true
  end
end

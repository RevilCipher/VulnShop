class MakeUserOptionalInComments < ActiveRecord::Migration[8.1]
  def change
     change_column :comments, :user_id, :integer, null: true
  end
end

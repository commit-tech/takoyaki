class ChangeTimeslotUserToDefaultuser < ActiveRecord::Migration[5.1]
  def change
    rename_column :timeslots, :user_id, :default_user_id
  end
end

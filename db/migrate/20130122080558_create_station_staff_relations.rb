class CreateStationStaffRelations < ActiveRecord::Migration
  def change
    create_table :station_staff_relations do |t|
      t.integer :station_id    #工位编号
      t.integer :staff_id     #员工编号
      t.number :current_day   #日期  年月日

      t.timestamps
    end
  end
end

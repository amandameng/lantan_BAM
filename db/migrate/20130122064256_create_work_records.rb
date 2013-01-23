class CreateWorkRecords < ActiveRecord::Migration
#  员工考勤
  def change
    create_table :work_records do |t|
      t.number :current_day   #年月日
      t.integer :attendance_num  #当月出息
      t.number :construct_num
      t.number :materials_used_num   #使用工具
      t.number :materials_consume_num  #材料损耗
      t.number :water_num     #水耗
      t.number :complaint_num   #投诉次数
      t.number :train_num  #培训次数
      t.number :violation_num  #违规次数

      t.timestamps
    end
  end
end

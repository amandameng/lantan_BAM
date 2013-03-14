#encoding: utf-8
require 'google_chart'
require 'net/https'
require 'uri'
require 'open-uri'
class ChartImage < ActiveRecord::Base

  #定时生成技师，接待平均水平统计表
  def self.generate_avg_chart_image

    year = Time.now.months_ago(1).strftime("%Y")
    month = Time.now.months_ago(1).strftime("%m")

    stores = Store.all
    avg_month_scores = {}
    stores.each do |store|
      avg_month_scores[store.id] = get_month_score_data(store, year, month)

    end
    generate_chart_images(avg_month_scores)
  end


  def self.get_month_score_data(store, year, month)

    month_scores = MonthScore.includes(:staff => :store).where("stores.id = #{store.id}").
      where("month_scores.current_month >= #{year}01 and month_scores.current_month <= #{year}#{month}").
      where("staffs.position = #{Staff::S_COMPANY[:FRONT]} or staffs.position = #{Staff::S_COMPANY[:TECHNICIAN]}").
      group_by{|s|s.staff.position}

    if month_scores.blank?
      zero_data = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

      return {Staff::S_COMPANY[:TECHNICIAN] => zero_data,
              Staff::S_COMPANY[:FRONT] => zero_data}
    end

    average_score_hart = {}
    month_scores.each do |key, value|
      scores = value.group_by{|m|m.current_month}
      data_array = []
      (0..12).collect{|i|key_value = (i>=10 ? year+i.to_s : year+"0#{i.to_s}").to_i and data_array << (scores[key_value].nil? ? 0 : ((scores[key_value].sum(&:manage_score) + scores[key_value].sum(&:sys_score))/scores[key_value].size))}
      average_score_hart[key] = data_array
    end

    average_score_hart

  end


  def self.generate_chart_images(avg_month_scores)

    avg_month_scores.each do |store_id, avg_data|
      avg_data.each do |key, value|
        hart_name = key == Staff::S_COMPANY[:TECHNICIAN] ? "技师平均水平统计" : "接待平均水平统计"

        types = key == Staff::S_COMPANY[:TECHNICIAN] ? 'TECHNICIAN' : 'FRONT'

        lc = GoogleChart::LineChart.new('1000x300', hart_name, false)
        lc.data hart_name,value , 'ff0000'
        lc.show_legend = true
        lc.max_value 100

        lc.axis :x, :labels =>['日期(月)', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'], :range => [0,12], :alignment => :center
        lc.axis :y, :labels => [0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100], :range => [0,10], :alignment => :center
        lc.grid :x_step => 100.0/12, :y_step => 100.0/10, :length_segment => 1, :length_blank => 3

        img_url=write_img(URI.escape(URI.unescape(lc.to_url({:chm => "o,0066FF,0,-1,6"}))),"#{store_id}","chart_images", types)

        ChartImage.create(:store_id => store_id, :types => types,
          :created_at => Time.now, :image_url => img_url, :current_day => Time.now.months_ago(1))

      end
    end

  end

  def self.write_img(url,index,file_n, types)  #上传图片
    file_name ="#{Time.now.to_i}_#{types}.jpg"
    dir = "#{File.expand_path(Rails.root)}/public/#{file_n}"
    Dir.mkdir(dir) unless File.directory?(dir)
    all_dir = "#{dir}/#{index}/"
    Dir.mkdir(all_dir) unless File.directory?(all_dir)
    file_url ="#{all_dir}#{file_name}"
    open(url) do |fin|
      File.open(file_url, "wb+") do |fout|
        while buf = fin.read(1024) do
          fout.write buf
        end
      end
    end
    return "/#{file_n}/#{index}/#{file_name}"
    puts "Chart #{index} success generated"
  end


  #每月定时生成员工绩效图表
  def self.generate_staff_score_chart
    year = Time.now.months_ago(1).strftime("%Y")
    month = Time.now.months_ago(1).strftime("%m")

    stores = Store.all
    stores.each do |store|
      store.staffs.each do |staff|
        according_staff_generate_score_chart(staff, year, month)
      end
    end
  end


  def self.according_staff_generate_score_chart(staff, year, month)

    month_scores = staff.month_scores.
      where("current_month >= #{year}01 and current_month <= #{year}#{month}").
      group_by{|s|s.current_month}

    data_array = []
    (0..12).collect{|i|key = (i>=10 ? year+i.to_s : year+"0#{i.to_s}").to_i and data_array << (month_scores[key].nil? ? 0 : (month_scores[key].sum(&:manage_score) + month_scores[key].sum(&:sys_score)))}

    lc = GoogleChart::LineChart.new('600x267', "员工绩效统计表", false)
    lc.data "绩效分",data_array , 'ff0000'
    lc.show_legend = true
    lc.max_value 100

    lc.axis :x, :labels =>['日期(月)', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'], :range => [0,12], :alignment => :center
    lc.axis :y, :labels => [0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100], :range => [0,10], :alignment => :center
    lc.grid :x_step => 100.0/12, :y_step => 100.0/10, :length_segment => 1, :length_blank => 3

    store_id = staff.store.id
    types = "STAFFMONTHSCORE"+staff.id.to_s
    img_url=write_img(URI.escape(URI.unescape(lc.to_url({:chm => "o,0066FF,0,-1,6"}))),"#{store_id}","chart_images", types)
    ChartImage.create(:store_id => store_id, :types => types,
      :created_at => Time.now, :image_url => img_url, :current_day => Time.now.months_ago(1))
  end

end

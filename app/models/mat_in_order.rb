#encoding: utf-8
class MatInOrder < ActiveRecord::Base
  belongs_to :material
  belongs_to :material_order
  belongs_to :staff

  def self.in_list page,per_page,store_id,sql = [nil,nil,nil]
    MatInOrder.where(sql[0]).where(sql[1]).where(sql[2]).where("materials.status=#{Material::STATUS[:NORMAL]} and materials.store_id=#{store_id}")
              .paginate(:select =>"materials.*,o.material_num,s.name staff_name,o.price out_price,o.created_at out_time, mo.code order_code",
                        :from => "mat_in_orders o",
                        :joins => "inner join materials on materials.id=o.material_id inner join staffs s on s.id=o.staff_id left join material_orders mo on mo.id=o.material_order_id",
                        :order => "o.created_at desc",
                        :page => page,:per_page => per_page)
  end
end

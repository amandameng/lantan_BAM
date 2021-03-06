#encoding: utf-8
class MarketManagesController < ApplicationController
  before_filter :sign?
  layout "complaint", :except => [:daily_consumption_receipt_blank, :stored_card_bill_blank]
  require 'will_paginate/array'

  before_filter :get_store, :only => [:stored_card_record, :daily_consumption_receipt, :stored_card_bill]

  #营业额汇总表
  def makets_totals
    session[:created],session[:ended]=(Time.now - Constant::PRE_DAY.days).strftime("%Y-%m-%d"),Time.now.strftime("%Y-%m-%d")
    months =[]
    @month_goal =MonthScore.sort_order_date(params[:store_id],session[:created],session[:ended])
    @month_goal.inject(Hash.new){|hash,order|
      hash[order.day].nil? ? hash[order.day]={order.pay_type=>order.price} : 
        hash[order.day].merge!(order.pay_type=>order.price);hash }.sort.reverse.each {|k,v| months << [k,v]}
    @months =months.paginate(:page=>params[:page],:per_page=>Constant::PER_PAGE)
    @total_num = @month_goal.inject(0){|num,order| num + order.price}
  end

  #营业额汇总查询
  def search_month
    session[:created],session[:ended]=params[:created],params[:ended]
    redirect_to "/stores/#{params[:store_id]}/market_manages/makets_list"
  end

  #营业额汇总查询列表
  def makets_list
    months =[]
    @month_goal =MonthScore.sort_order_date(params[:store_id],session[:created],session[:ended])
    @month_goal.inject(Hash.new){|hash,order|
      hash[order.day].nil? ? hash[order.day]={order.pay_type=>order.price} : 
        hash[order.day].merge!(order.pay_type=>order.price);hash }.sort.reverse.each {|k,v| months << [k,v]}
    @months =months.paginate(:page=>params[:page],:per_page=>Constant::PER_PAGE)
    @total_num =@month_goal.inject(0){|num,order| num+order.price}
    render 'makets_totals'
  end

  #销售报表
  def makets_reports
    session[:r_created],session[:r_ended],session[:time]=(Time.now - Constant::PRE_DAY.days).strftime("%Y-%m-%d"),Time.now.strftime("%Y-%m-%d"),Sale::DISC_TIME[:DAY]
  end


  def load_service
    @total_service,@total_serv,serv = {},0,[]
    session[:r_created],session[:r_ended],session[:time]=params[:created],params[:ended],params[:time].to_i
    orders = MonthScore.search_kind_order(session[:r_created],session[:r_ended],session[:time],params[:store_id],Product::PROD_TYPES[:SERVICE])
    unless orders.blank?
      pays =MonthScore.normal_ids(orders.map(&:id),Product::PROD_TYPES[:SERVICE],session[:time]).inject(Hash.new){ |hash,pay|
        hash["#{pay.product_id}-#{pay.day}"].nil? ? hash["#{pay.product_id}-#{pay.day}"]=(pay.price.nil? ? 0 : pay.price) :
          hash["#{pay.product_id}-#{pay.day}"] += (pay.price.nil? ? 0 : pay.price);hash}
      orders.inject(Hash.new){|hash,order|
        hash["#{order.id}-#{order.day}"].nil? ? hash["#{order.id}-#{order.day}"]= order.sum : hash["#{order.id}-#{order.day}"] += order.sum;hash}.each {
        |key,value|@total_service[key] = (value.nil? ? 0 : value)- (pays[key].nil? ? 0 : pays[key])}
      orders.inject(Hash.new){
        |hash,prod|@total_serv += @total_service["#{prod.id}-#{prod.day}"];hash[prod.day].nil? ? hash[prod.day]= [prod] : hash[prod.day] << prod ;hash
      }.sort.reverse.each {|k,v| serv << [k,v]} if orders.any?
      @serv = serv.paginate(:page=>params[:page],:per_page=>Constant::PER_PAGE)
    end
  end

  def load_product
    @total_product,@total_prod,prods = {},0,[]
    session[:r_created],session[:r_ended],session[:time]=params[:created],params[:ended],params[:time].to_i
    orders = MonthScore.search_kind_order(session[:r_created],session[:r_ended],session[:time],params[:store_id],Product::PROD_TYPES[:PRODUCT])
    unless orders.blank?
      pays =MonthScore.normal_ids(orders.map(&:id),Product::PROD_TYPES[:PRODUCT],session[:time]).inject(Hash.new){ |hash,pay|
        hash["#{pay.product_id}-#{pay.day}"].nil? ? hash["#{pay.product_id}-#{pay.day}"]=(pay.price.nil? ? 0 : pay.price) :
          hash["#{pay.product_id}-#{pay.day}"] += (pay.price.nil? ? 0 : pay.price);hash}
      orders.inject(Hash.new){|hash,order|
        hash["#{order.id}-#{order.day}"].nil? ? hash["#{order.id}-#{order.day}"]= order.sum : hash["#{order.id}-#{order.day}"] += order.sum;hash}.each {
        |key,value|@total_product[key] = (value.nil? ? 0 : value)- (pays[key].nil? ? 0 : pays[key])}
      orders.inject(Hash.new){
        |hash,prod|@total_prod += @total_product["#{prod.id}-#{prod.day}"];hash[prod.day].nil? ? hash[prod.day]= [prod] : hash[prod.day] << prod ;hash
      }.sort.reverse.each {|k,v| prods << [k,v]} if orders.any?
      @prods = prods.paginate(:page=>params[:page],:per_page=>Constant::PER_PAGE)
    end
  end

  def load_pcard
    @total_product,@total_fee,pcards = {},0,[]
    session[:r_created],session[:r_ended],session[:time]=params[:created],params[:ended],params[:time].to_i
    pays = MonthScore.sort_pay_types(params[:store_id],session[:time],session[:r_created],session[:r_ended])
    pays.inject(Hash.new){ |hash,prod|
      @total_fee += prod.sum; hash[prod.day].nil? ? hash[prod.day]= [prod] : hash[prod.day] << prod ;hash
    }.sort.reverse.each {|k,v| pcards << [k,v]}
    @pcards = pcards.paginate(:page=>params[:page],:per_page=>Constant::PER_PAGE)
    @products = Product.where("id in (#{pays.map(&:product_id).join(',')})").inject(Hash.new){|hash,prod| hash[prod.id]=prod;hash}
  end


  #目标销售额
  def index
    goals =GoalSale.where("store_id=#{params[:store_id]}").inject(Hash.new){|hash,sale|
      hash[sale.ended_at.strftime("%Y-%m-%d")].nil? ? hash[sale.ended_at.strftime("%Y-%m-%d")]=[sale] : hash[sale.ended_at.strftime("%Y-%m-%d")] << [sale];hash }
    @goal_hash =GoalSale.total_type(params[:store_id]).inject(Hash.new){|hash,goal|
      hash[goal.goal_sale_id].nil? ? hash[goal.goal_sale_id]=[goal] : hash[goal.goal_sale_id] << goal;hash }
    @new_goals =goals.select {|key,value| key >= Time.now.strftime("%Y-%m-%d")}.values.flatten
    @old_goals =goals.select {|key,value| key < Time.now.strftime("%Y-%m-%d")}.values.flatten
  end

  #创建目标销售额
  def create
    parms = {:started_at=>params[:created],:ended_at=>params[:ended],:store_id=>params[:store_id],:created_at=>Time.now.strftime("%Y-%m-%d")}
    goal=GoalSale.create(parms)
    parm_type ={:goal_sale_id=>goal.id}
    max_type = GoalSale.max_type(params[:store_id])
    index =1
    params[:goal].each do |k,v|
      type_name=MonthScore::GOAL_NAME[k.to_i].nil? ? params[:val][k] : MonthScore::GOAL_NAME[k.to_i]
      types= MonthScore::GOAL_NAME[k.to_i].nil? ?  (max_type.max.nil? ? GoalSale::TYPES_NAMES.keys.max : max_type.max)+index : k
      unless type_name==""
        parm_type.merge!(:type_name=>type_name,:goal_price=>v,:types=>types)
        GoalSaleType.create(parm_type)
        index +=1 if k.to_i >=4
      end
    end
    redirect_to "/stores/#{params[:store_id]}/market_manages/"
  end

  #活动订单显示
  def sale_orders
    session[:o_created],session[:o_ended],session[:order_name]=nil,nil,nil
    orders = Sale.count_sale_orders(params[:store_id])
    @sale_orders =  orders.paginate(:page=>params[:page],:per_page=>Constant::PER_PAGE)
    unless @sale_orders.blank?
      pays = OrderPayType.find_by_sql("select price,pay_type,order_id from order_pay_types where order_id in (#{@sale_orders.map(&:o_id).join(',')}) ").inject(Hash.new) {
        |hash,order_pay| hash[order_pay.order_id].nil? ? hash[order_pay.order_id]=[order_pay] : hash[order_pay.order_id] << order_pay;hash }
      @hash_favor = {}
      pays.each {|key,value| @hash_favor[key]=value.inject(Hash.new){|hash,pay| hash[pay.pay_type].nil? ? hash[pay.pay_type]=pay.price : hash[pay.pay_type] += pay.price;hash }}
      @sale_names =orders.map(&:name)
    end
  end

  def search_sale_order
    session[:o_created],session[:o_ended],session[:order_name]=nil,nil,nil
    session[:o_created],session[:o_ended],session[:order_name]=params[:o_created],params[:o_ended],params[:order_name]
    redirect_to "/stores/#{params[:store_id]}/market_manages/sale_order_list"
  end

  def sale_order_list
    orders = Sale.count_sale_orders_search(params[:store_id],session[:o_created],session[:o_ended],session[:order_name])
    @sale_orders =  orders.paginate(:page=>params[:page],:per_page=>Constant::PER_PAGE)
    unless @sale_orders.blank?
      pays = OrderPayType.find_by_sql("select price,pay_type,order_id from order_pay_types where order_id in (#{@sale_orders.map(&:o_id).join(',')}) ").inject(Hash.new) {
        |hash,order_pay| hash[order_pay.order_id].nil? ? hash[order_pay.order_id]=[order_pay] : hash[order_pay.order_id] << order_pay;hash }
      @hash_favor = {}
      pays.each {|key,value| @hash_favor[key]=value.inject(Hash.new){|hash,pay| hash[pay.pay_type].nil? ? hash[pay.pay_type]=pay.price : hash[pay.pay_type] += pay.price;hash }}
    end
    @sale_names =Sale.count_sale_orders_search(params[:store_id]).map(&:name)
    render 'sale_orders'
  end

  def stored_card_record
    @start_at, @end_at = params[:started_at], params[:ended_at]
    started_at_sql = (@start_at.nil? || @start_at.empty?) ? '1 = 1' : "o.created_at >= '#{@start_at}'"
    ended_at_sql = (@end_at.nil? || @end_at.empty?) ? '1 = 1' : "o.created_at <= '#{@end_at} 23:59:59'"

    order_details = Order.find_by_sql("select o.id,o.code,opt.price price,opt.created_at created_at,p.name product_name from orders o
                                inner join order_pay_types opt on opt.order_id = o.id inner join order_prod_relations op on
                                op.order_id = o.id inner join products p on op.product_id = p.id
                                where opt.pay_type=#{OrderPayType::PAY_TYPES[:SV_CARD]} and
                                o.status in (#{Order::STATUS[:BEEN_PAYMENT]}, #{Order::STATUS[:FINISHED]}) and
                                #{started_at_sql} and #{ended_at_sql}")

    pcar_relations = CPcardRelation.find_by_sql(["select cpr.order_id order_id, 1 pro_num, pc.price price, pc.name name
        from c_pcard_relations cpr inner join package_cards pc
        on pc.id = cpr.package_card_id where cpr.order_id in (?)", order_details])
    
    orders = {}
    order_details.each do |order|
      orders.keys.include?(order.id) ? orders[order.id][:product_name] += (","+order.product_name) : orders[order.id] = order
    end
    pcar_relations.each do |pr|
      orders.keys.include?(pr.order_id) ? orders[pr.order_id][:product_name] += (","+pr.name) : orders[pr.order_id] = pr
    end
    @total_price = orders.values.sum(&:price)
    @orders = orders.values.paginate(:page => params[:page] ||= 1, :per_page => Staff::PerPage)
    
  end

  def daily_consumption_receipt
    @search_time = params[:search_time] || Time.now.strftime("%Y-%m-%d")
    
#    @current_day_total = Order.where("created_at <= '#{Time.now}'").
#      where("created_at >= '#{Time.now.strftime("%Y-%m-%d")}'").
#      where("status = #{Order::STATUS[:BEEN_PAYMENT]} or status = #{Order::STATUS[:FINISHED]}").sum(:price)

    orders = Order.where("created_at <= '#{@search_time} 23:59:59'").
      where("created_at >= '#{@search_time} 00:00:00'").
      where("status = #{Order::STATUS[:BEEN_PAYMENT]} or status = #{Order::STATUS[:FINISHED]}")
    @search_total = orders.sum(:price)
    @orders = orders.paginate(:page => params[:page] ||= 1, :per_page => Staff::PerPage)
  end

  def daily_consumption_receipt_blank
    @search_time = params[:search_time]
    @orders = Order.where("created_at <= '#{@search_time} 23:59:59'").
      where("created_at >= '#{@search_time} 00:00:00'").
      where("status = #{Order::STATUS[:BEEN_PAYMENT]} or status = #{Order::STATUS[:FINISHED]}")
    @search_total = @orders.sum(:price)
  end

  def stored_card_bill
    @start_at, @end_at = params[:started_at], params[:ended_at]
    
    svc_returns = shared_stored_card_bill(@start_at, @end_at, @store.id)
    @price = svc_returns.last.nil? ? 0 : sprintf('%.2f', svc_returns.last.total_price)
    @svc_returns = svc_returns.paginate(:page=>params[:page] || 1,:per_page=> Constant::PER_PAGE)
  end

  def stored_card_bill_blank
    @svc_returns = shared_stored_card_bill(params[:started_at], params[:ended_at], params[:store_id])
  end

  def gross_profit
    @orders = Order.includes(:order_prod_relations,:c_pcard_relations => {:package_card => {:pcard_prod_relations => :product}}).where(:status => Order::VALID_STATUS)
    .where("date_format(created_at,'%Y-%m-%d') = curdate()")
    .select("distinct orders.*")
    .paginate(:page=>params[:page] || 1,:per_page=> Constant::PER_PAGE )
  end

  def search_gross_profit
    sql = []
    start_sql = params[:o_started].blank? ? nil : "date_format(orders.created_at,'%Y-%m-%d') >= '#{params[:o_started]}'"
    end_sql = params[:o_ended].blank? ? nil : "date_format(orders.created_at,'%Y-%m-%d') <= '#{params[:o_ended]}'"
    types_sql = params[:prod_types] =="-1" ? nil : "products.types = #{params[:prod_types]}"
   
    @flag = "product"
    if types_sql.nil?
      sql<< start_sql << end_sql
      sql = sql.compact.join(" and ")
      @orders = Order.includes(:order_prod_relations,:c_pcard_relations => {:package_card => {:pcard_prod_relations => :product}}).where(:status => Order::VALID_STATUS)
      .where(sql)
      .select("distinct orders.*")
      .paginate(:page=>params[:page] || 1,:per_page=> Constant::PER_PAGE )
      @flag = "order"
    else
      sql<< start_sql << end_sql << types_sql
      sql = sql.compact.join(" and ")
      @orders = Order.joins(:order_prod_relations => :product).where(:status => Order::VALID_STATUS)
      .where(sql).select("orders.id, date_format(orders.created_at,'%Y-%m-%d') o_created_at, orders.code, products.types").uniq
      .paginate(:page => params[:page] || 1, :per_page => Constant::PER_PAGE)
      @order_pay_types = OrderPayType.where(:order_id => @orders.map(&:id) ).where("product_id is not null").group_by{|opt| opt.order_id}
      #      @o_pcard_relations = OPcardRelation.where(:order_id => @orders.map(&:id)).group_by{|opt| opt.order_id}
      @order_prod_relations = OrderProdRelation.joins(:product).where(:order_id => @orders.map(&:id)).where(types_sql).group_by{|opt| opt.order_id}
    end
  end

  private
  def get_store
    @store = Store.find_by_id(params[:store_id])
  end

  def shared_stored_card_bill(started_at, ended_at, store_id)
    started_at_sql = (started_at.nil? || started_at.empty?) ? '1 = 1' : "srr.created_at >= '#{started_at}'"
    ended_at_sql = (ended_at.nil? || ended_at.empty?) ? '1 = 1' : "srr.created_at <= '#{ended_at} 23:59:59'"

    relation_order_sql = "select srr.*,o.code code,o.id o_id from svc_return_records srr
                          left join orders o on o.id = srr.target_id where #{started_at_sql}
                          and o.status in (#{Order::STATUS[:BEEN_PAYMENT]}, #{Order::STATUS[:FINISHED]}) 
                          and #{ended_at_sql} and srr.store_id=#{store_id} and
                          srr.types=#{SvcReturnRecord::TYPES[:OUT]}"
    order_svc_returns = SvcReturnRecord.find_by_sql(relation_order_sql)

    relation_material_order_sql = "select srr.*,mo.code code,mo.id mo_id from svc_return_records srr
                          left join material_orders mo on mo.id = srr.target_id where #{started_at_sql}
                          and mo.status = #{MaterialOrder::STATUS[:pay]}
                          and #{ended_at_sql} and srr.store_id=#{store_id} and
                          srr.types=#{SvcReturnRecord::TYPES[:IN]}"
    material_order_svc_returns = SvcReturnRecord.find_by_sql(relation_material_order_sql)

    (order_svc_returns + material_order_svc_returns).sort{|a,b| a[:id] <=> b[:id]}
  end
end
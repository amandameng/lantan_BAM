#encoding: utf-8
class CustomersController < ApplicationController
  include RemotePaginateHelper
  layout "customer"
  before_filter :customer_tips

  def index
    session[:c_types] = nil
    session[:car_num] = nil
    session[:started_at] = nil
    session[:ended_at] = nil
    session[:name] = nil
    session[:phone] = nil
    session[:is_vip] = nil
    @store = Store.find(params[:store_id].to_i)
    @customers = Customer.search_customer(params[:c_types], params[:car_num], params[:started_at], params[:ended_at],
      params[:name], params[:phone], params[:is_vip], params[:page])
  end

  def search
    session[:c_types] = params[:c_types]
    session[:car_num] = params[:car_num]
    session[:started_at] = params[:started_at]
    session[:ended_at] = params[:ended_at]
    session[:name] = params[:name]
    session[:phone] = params[:phone]
    session[:is_vip] = params[:is_vip]
    redirect_to "/stores/#{params[:store_id]}/customers/search_list"
  end

  def search_list
    @store = Store.find(params[:store_id].to_i)
    @customers = Customer.search_customer(session[:c_types], session[:car_num], session[:started_at], session[:ended_at],
      session[:name], session[:phone], session[:is_vip], params[:page])
    render "index"
  end

  def destroy
    @customer = Customer.find(params[:id].to_i)
    @customer.update_attributes(:status => Customer::STATUS[:DELETED])
    redirect_to request.referer
  end

  def create
    if params[:new_name] and params[:mobilephone]
      Customer.transaction do
        customer = Customer.create(:name => params[:new_name].strip, :mobilephone => params[:mobilephone].strip,
          :other_way => params[:other_way].strip, :sex => params[:sex], :birthday => params[:birthday],
          :address => params[:address], :status => Customer::STATUS[:NOMAL],
          :types => Customer::TYPES[:NORMAL], :is_vip => Customer::IS_VIP[:NORMAL])
        car_num = CarNum.find_or_create_by_num(params[:new_car_num].strip)
        CustomerNumRelation.delete_all(["car_num_id = ?", car_num.id])
        CustomerNumRelation.create(:car_num_id => car_num.id, :customer_id => customer.id)
      end
    end
    redirect_to "/stores/#{params[:store_id]}/customers"
  end

  def edit
    @store = Store.find(params[:store_id].to_i)
    @customer = Customer.find(params[:id].to_i)
  end

  def update
    if params[:name] and params[:mobilephone]
      customer = Customer.find(params[:id].to_i)
      customer.update_attributes(:name => params[:name].strip, :mobilephone => params[:mobilephone].strip,
        :other_way => params[:other_way].strip, :sex => params[:sex], :birthday => params[:birthday],
        :address => params[:address])
    end
    redirect_to "/stores/#{params[:store_id]}/customers"
  end

  def customer_mark
    customer = Customer.find(params[:c_customer_id].to_i)
    customer.update_attributes(:mark => params[:mark].strip)
    flash[:notice] = "备注成功。"
    redirect_to "/stores/#{params[:store_id]}/customers"
  end

  def single_send_message
    unless params[:content].strip.empty? or params[:m_customer_id].nil?
      MessageRecord.transaction do
        message_record = MessageRecord.create(:store_id => params[:store_id].to_i, :content => params[:content].strip,
          :status => MessageRecord::STATUS[:NOMAL], :send_at => Time.now)
        customer = Customer.find(params[:m_customer_id].to_i)
        SendMessage.create(:message_record_id => message_record.id, :customer_id => customer.id,
          :content => params[:content].strip.gsub("%name%", customer.name), :phone => customer.mobilephone,
          :send_at => Time.now, :status => MessageRecord::STATUS[:NOMAL])
        flash[:notice] = "短信发送成功。"
      end
    end
    redirect_to "/stores/#{params[:store_id]}/customers"
  end

  def show
    @store = Store.find(params[:store_id].to_i)
    @customer = Customer.find(params[:id].to_i)
    @car_nums = CarNum.find_by_sql(["select c.num, cb.name b_name, cm.name m_name, c.buy_year from car_nums c
        left join car_models cm on cm.id = c.car_model_id
        left join car_brands cb on cb.id = cm.car_brand_id
        inner join customer_num_relations cr on cr.car_num_id = c.id
        where cr.customer_id = ?", @customer.id])
    @orders = Order.one_customer_orders(Order::STATUS[:DELETED], params[:store_id].to_i, @customer.id, 1, params[:page])
    @product_hash = OrderProdRelation.order_products(@orders)
    @order_pay_type = OrderPayType.order_pay_types(@orders)
    
    @revisits = Revisit.one_customer_revists(params[:store_id].to_i, @customer.id, 1, params[:page])
    @complaints = Complaint.one_customer_complaint(params[:store_id].to_i, @customer.id, 1, params[:page])    
  end

  def order_prods
    @store = Store.find(params[:store_id].to_i)
    @customer = Customer.find(params[:id].to_i)
    @orders = Order.one_customer_orders(Order::STATUS[:DELETED], params[:store_id].to_i, @customer.id, 1, params[:page])
    @product_hash = OrderProdRelation.order_products(@orders)
    @order_pay_type = OrderPayType.order_pay_types(@orders)
    respond_to do |format|
      format.js
    end
  end

  def revisits
    @store = Store.find(params[:store_id].to_i)
    @customer = Customer.find(params[:id].to_i)
    @revisits = Revisit.one_customer_revists(params[:store_id].to_i, @customer.id, 1, params[:page])
    respond_to do |format|
      format.js
    end
  end

  def complaints
    @store = Store.find(params[:store_id].to_i)
    @customer = Customer.find(params[:id].to_i)
    @complaints = Complaint.one_customer_complaint(params[:store_id].to_i, @customer.id, 1, params[:page])
    respond_to do |format|
      format.js
    end
  end
  

  def get_car_brands
    respond_to do |format|
      format.json {
        render :json => CarBrand.get_brand_by_capital(params[:capital_id].to_i)
      }
    end
  end

  def get_car_models
    respond_to do |format|
      format.json {
        render :json => CarModel.get_model_by_brand(params[:brand_id].to_i)
      }
    end
  end

  def check_car_num
    car_num = CarNum.find_by_num(params[:car_num].strip)
    respond_to do |format|
      format.json {
        render :json => {:is_has => car_num.nil?}
      }
    end
  end

end

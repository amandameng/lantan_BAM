#encoding: utf-8
class SalariesController < ApplicationController

  def destroy
    @store = Store.find_by_id(params[:store_id])
    
    salary = Salary.find_by_id(params[:id])
    salary.update_attribute(:status, true) if salary
    
    @salaries = salary.staff.salaries.where("status = false").
      paginate(:page => params[:page] ||= 1, :per_page => Staff::PerPage)
    respond_to do |format|
      format.js
    end
  end

  def update
    salary = Salary.find_by_id(params[:id])
    salary.update_attributes(:reward_num => params[:reward_num],
      :deduct_num => params[:deduct_num]) if salary
    render :text => "success"
  end
  
end

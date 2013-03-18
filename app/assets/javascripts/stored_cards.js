// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

$(document).ready(function(){

   //库存成本统计选择月份提交
   $("#statistics_month_select").change(function(){
      $(this).parents('form').submit();
      return false;
   });

   //查看员工绩效统计
   $(".staff_month_score_detail").click(function(){
      var id = $(this).attr("id");
      var store_id = $("#store_id").val();
      $.ajax({
            async:true,
            type : 'get',
            dataType : 'script',
            url : "/stores/"+ store_id+"/staff_manages/"+ id
      });
      return false;
   });

   //员工绩效  根据年份统计
   $("#statistics_year").live("change", function(){
      var year = $(this).val();
      var id = $(this).attr("name");
      var store_id = $("#store_id").val();
      $.ajax({
            type : 'get',
            url : "/stores/"+ store_id+"/staff_manages/get_year_staff_hart",
            data : {
                year:year,
                id : id
            },
            success: function(data){
               $("#staff_month_chart_detail").find(".tj_pic").find('img').attr("src", data);
            }
      });
      return false;
   });

   //按年份统计平均水平
   $("#statistics_year").change(function(){
       $(this).parents('form').submit();
       return false;
   })

   //打印每日销售单据
   $("#print_daily_receipt").click(function(){
      var search_time = $(this).attr("name");
      var store_id = $("#store_id").val();
      $.ajax({
            async:true,
            type : 'get',
            dataType : 'script',
            url : "/stores/"+ store_id+"/market_manages/daily_consumption_receipt",
            data : {search_time : search_time}
      });
      return false;
   });

   //打印储值卡对账单
   $("#print_bill").click(function(){
      var started_at = $(this).attr("started_at");
      var ended_at = $(this).attr("ended_at");
      var store_id = $("#store_id").val();
      $.ajax({
            async:true,
            type : 'get',
            dataType : 'script',
            url : "/stores/"+ store_id+"/market_manages/stored_card_bill",
            data : {started_at : started_at,
                    ended_at : ended_at}
      });
      return false;
   });

});

function check_goal(){
    var created  =$("#created").val();
    var ended =$("#ended").val();
    var types_name =[];
    if ((created=="" || created.length==0) && (ended=="" || ended.length )){
        alert("请选择目标销售额的起止日期！");
        return false;
    }
    var carry_out =true;
    $(".popup_body_area div[id *='item']").each(function(){
        if ($(this).find("input").length==1){
            var label =$(this).find("label").html();
            types_name.push(label)
            if ($(this).find("input").val()==0 || $(this).find("input").length==0){
                alert("请输入"+label+"的金额");
                carry_out=false;
                return false
            }
        }else{
            var first=$(this).find("input").first().val();
            if (first!="" || first.length!=0 ){
                var second=$(this).find("input").last().val();
                if(second=="" || second.length==0){
                    alert("请输入"+first+"的金额");
                    carry_out=false;
                    return false;
                }
                if (types_name.indexOf(first)>=0 ){
                    alert("”"+first+"“ 已经存在，请检查");
                    carry_out=false;
                    return false;
                }
                types_name.push(first)
            }
        }
    })
    if(carry_out && confirm("目标销售额不能更改，您确定创建该目标吗？")){
        $("#create_goal").submit();
    }
}

function add_div(){
    var num=$(".popup_body_area div[id *='item']");
    var  str='<div class="item" id=item_'+ num.length+'><input type="text" name="val['+num.length +']" size="12" class="input_s" /><input name="goal['+num.length +']" type="text" /></div>';
    $(num[num.length-1]).after(str);
}

function select_customers() {
    var checkboxes = $("#search_div input:checked");
    var send_html = "";
    var customer_ids = "";
    for (var i=0; i<checkboxes.length; i++) {
        send_html += "<div id='cus_"+ checkboxes[i].value +"'><em>"+ $("#label_" + checkboxes[i].value).html()
            + "</em><a href='javascript:void(0);' class='remove_a' onclick='delete_cus("+ checkboxes[i].value +")'>删除</a></div>";
        customer_ids == "" ? (customer_ids += checkboxes[i].value) : (customer_ids += "," + checkboxes[i].value);
    }
    $("#customer_ids").val(customer_ids);
    $("#send_div").html(send_html);
}

function delete_cus(customer_id) {
   $("#c_" + customer_id).removeAttr("checked");
   $("#cus_" + customer_id).remove();
   var ids = $("#customer_ids").val();
   if (ids != null && ids != "") {
       var ids_arr = ids.split(",");
       var new_ids = [];
       for (var i=0; i<ids_arr.length; i++) {
           if (ids_arr[i] != ""+customer_id) {
               new_ids.push(ids_arr[i]);
           }
       }
       $("#customer_ids").attr("value", new_ids.join(","));
   }
}

function check_message() {
    if ($.trim($("#customer_ids").val()) == "") {
        tishi_alert("请选择您要发信息的客户。")
        return false;
    }
    if ($.trim($("#content").val()) == "") {
        tishi_alert("请您填写需要发送的内容。");
        return false;
    }
    return true;
}

function check_customer() {
    if ($.trim($("#name").val()) == "") {
        alert("请输入客户姓名");
        return false;
    }
    if ($.trim($("#mobilephone").val()) == "") {
        alert("请输入客户手机号码");
        return false;
    }
    return true;
}

function customer_mark(customer_id) {
    $("#mark_div").show();
    $("#c_customer_id").val(customer_id);
}

function single_send_message(customer_id) {
    $("#message_div").show();
    $("#m_customer_id").val(customer_id);
}

function check_single_send() {
    if ($.trim($("#content").val()) == "") {
        alert("请您填写需要发送的内容。");
        return false;
    }
    return true;
}
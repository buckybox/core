$(function() {
  $("#bank_payment_details").toggle();
  $("#make_a_payment, #close_bank_payment_details").click(function(){
    $("#make_a_payment").toggle();
    $("#bank_payment_details").toggle();
    return false;
  });
})

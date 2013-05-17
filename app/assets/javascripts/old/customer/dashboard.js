$(function() {
  $("#bank_payment_details").toggle();
  $("#make_a_payment, #close_bank_payment_details").click(function(){
    $("#make_a_payment").toggle();
    $("#bank_payment_details").toggle();
    return false;
  });

  var phone_inputs = $('#address-modal input[type="tel"]');
  phone_inputs.keyup(update_phone_inputs_style);
  update_phone_inputs_style();

  function update_phone_inputs_style() {
    phone_inputs.addClass('required');

    var input = phone_inputs.map(function() {
      if ($.trim(this.value).length) {
        return this;
      }
    });

    if (input.length) {
      phone_inputs.not(input).removeClass('required');
    }
  }
})

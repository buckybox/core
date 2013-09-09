$(function(){
  $("#business_information_submit").click(function(){
    if($("#distributor_has_balance_threshold:checked").size() !== 0){
      $("#business_information_submit").attr('disabled', 'disabled');
      $.post("/distributor/settings/spend_limit_confirmation",
             {spend_limit: $("#distributor_default_balance_threshold").val(),
              update_existing: $("#distributor_spend_limit_on_all_customers:checked").size(),
              send_halt_email: $("#distributor_send_halted_email:checked").size()},
             function(data, textStatus, jqXHR){
               if(data === "safe"){
                $("#business_information_submit").closest("form").submit();
               }else if(confirm(data)){
                $("#business_information_submit").closest("form").submit();
               }else{
                $("#business_information_submit").removeAttr('disabled');
               }
             }
            ).error(function(){
              $("#business_information_submit").removeAttr('disabled');
            });
    }else{
      return true;
    }
    return false;
  });

  var update_balance_threshold_display = function(){
    if($("#distributor_has_balance_threshold:checked").size() === 0) {
      $("#balance_threshold").hide('highlight');
    } else {
      $("#balance_threshold").show('highlight');
    }
  }
  // Show/hide spend limit (balance_threshold) extra fields
  $("#distributor_has_balance_threshold").click(update_balance_threshold_display);

  if ($("#payments").length) {
    var update_preview = function() {
      var klass = this.id;
      var inputs = $('#new_bank_deposit [id="' + klass + '"]');
      var text = '';
      inputs.each(function() {
        if (text !== '') text += '-';
        text += this.value;
      });

      $(".payment-message:visible ." + klass).text(text);
    };

    var fields = $("#new_bank_deposit :input:visible");
    fields.on('keyup', update_preview);
    fields.trigger('keyup');
  }
});

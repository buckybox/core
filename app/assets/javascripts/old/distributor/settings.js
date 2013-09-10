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
      if (!klass) return;

      var inputs = $('form [id="' + klass + '"]');
      var text = '';
      inputs.each(function() {
        if (text !== '') text += '-';
        text += this.value;
      });

      text = text.replace(/(\n|\r|\r\n)/g, '<br>');
      $(".payment-message ." + klass)[0].innerHTML = text;

      $("#payments .preview").toggle(
        $("#payments .preview .payment-message").text().trim() != ""
      );
    };

    var fields = $("form :input:visible");
    fields.on('keyup', update_preview);
    fields.trigger('keyup');

    // fields.on('keyup', function() {
    //   console.log($(this).val().length, $(this).prop("maxlength"));
    //   // if ($(this).val().length == $(this).prop("maxlength")) {
    //     $(this).next("input").focus();
    //   // }
    // });

    fields.filter('[data-toggle="tooltip"]').tooltip({ 'trigger': 'focus' });
  }
});


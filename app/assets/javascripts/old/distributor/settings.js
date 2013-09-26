$(function(){
  $("#organisation_submit").click(function(){
    if ($("#distributor_has_balance_threshold:checked").size() !== 0) {
      $("#organisation_submit").attr('disabled', 'disabled');

      $.post("/distributor/settings/spend_limit_confirmation", {
         spend_limit: $("#distributor_default_balance_threshold").val(),
         update_existing: $("#distributor_spend_limit_on_all_customers:checked").size(),
         send_halt_email: $("#distributor_send_halted_email:checked").size()
       },
       function(data) {
         if (data !== "safe" && !confirm(data)) return false;
       }
      ).complete(function() {
        $("#organisation_submit").removeAttr('disabled');
      });
    }
  });

  // Show/hide spend limit (balance_threshold) extra fields
  $("#distributor_has_balance_threshold").change(function() {
    $("#balance_threshold").toggle(
      $("#distributor_has_balance_threshold").is(":checked")
    );
  }).trigger("change");


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

    fields.filter('[data-toggle="tooltip"]').tooltip({ 'trigger': 'focus' });
  }
});


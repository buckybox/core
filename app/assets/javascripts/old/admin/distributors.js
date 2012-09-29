$(function() {
  if($('#invoice_start_date').length > 0) { // prevent this from loading everywhere there is a form
    $("#invoice_start_date").dateinput({ format: 'yyyy-mm-dd' });
    $("#invoice_end_date").dateinput({ format: 'yyyy-mm-dd' });

    update_invoice = function() {
      $('#invoice_loader').show();

      $.getJSON(
        $("form").attr('action'), 
        {
          start_date: $("#invoice_start_date").val(),
          end_date: $("#invoice_end_date").val()
        },
        function(data) {
          $("#deliveries_made").html(data.delivered);
          $("#deliveries_cancelled").html(data.cancelled);
          $("#value_shipped").html(data.value);
          $('#invoice_loader').hide();
        }
      );
    };

    update_invoice();

    $("#invoice_start_date").change(update_invoice);
    $("#invoice_end_date").change(update_invoice);
  }
});

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

  // Show/hide spend limit (balance_threshold) extra fields
  $("#distributor_has_balance_threshold").click(function(){
    if($("#balance_threshold").is(":visible")) {
      $("#balance_threshold").hide('highlight');
    } else {
      $("#balance_threshold").show('highlight');
    }
  });

  // Confirm spend limit changes if they affect customers directly
  $("#edit_distributor_submit").click(function(){
    if($("#distributor_has_balance_threshold:checked").size() !== 0){
      $("#edit_distributor_submit").attr('disabled', 'disabled');
      $.post("/admin/distributors/spend_limit_confirmation",
             {spend_limit: $("#distributor_default_balance_threshold").val(),
              update_existing: $("#distributor_spend_limit_on_all_customers:checked").size(),
              // If both email checkboxes are checked return '1', otherwise '0'
              send_halt_email: $("#distributor_send_halted_email:checked").size() * $("#distributor_send_email:checked").size(),
              form_id: $("#edit_distributor_submit").closest("form").attr("id")},
             function(data, textStatus, jqXHR){
               if(data === "safe"){
                $("#edit_distributor_submit").closest("form").submit();
               }else if(confirm(data)){
                $("#edit_distributor_submit").closest("form").submit();
               }else{
                $("#edit_distributor_submit").removeAttr('disabled');
               }
             }
            ).error(function(){
              $("#edit_distributor_submit").removeAttr('disabled');
            });
    }else{
      return true;
    }
    return false;
  });
});

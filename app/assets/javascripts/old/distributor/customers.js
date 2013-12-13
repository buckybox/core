$(function() {


  //////////////////////////////////////////////////////////////////////////////
  // Orders management
  //

  var order_pause_init = function() {
    $('.initial-link a').click(function() {
      fromPausingElementFind(this, '.initial-link').hide();
      fromPausingElementFind(this, '.form-selection').css('display', 'inline-block');
      return false;
    });

    $('.cancel-link a').click(function() {
      fromPausingElementFind(this, '.form-selection').hide();

      var resulting_link = fromPausingElementFind(this, '.resulting-link');

      if(resulting_link.data('date')) {
        resulting_link.css('display', 'inline-block');
      }
      else {
        fromPausingElementFind(this, '.initial-link').css('display', 'inline-block');
      }

      return false;
    });

    $('.remove-link a').click(function() {
      fromPausingElementFind(this, '.form-selection').hide();
      fromPausingElementFind(this, '.remove-link').hide();
      fromPausingElementFind(this, '.initial-link').css('display', 'inline-block');
      return false;
    });

    $('.pause .remove-link a').click(function() {
      var resume = $(this).closest('.pausing').find('.resume');
      resume.hide();
      resume.find('.initial-link').css('display', 'inline-block');
      resume.find('.form-selection').hide();
      resume.find('.remove-link').hide();
      resume.find('.resulting-link').hide();

      var form = fromPausingElementFind(this, '.form-selection form');
      var url = $(this).attr('href');
      var order_id = form.closest("tr[data-order-id]").attr('data-order-id');
      $.ajax({ type: 'POST',
               dataType: 'html',
               url: url,
               success: function(data) {
                 reload_pause_details(order_id, data);
               },
               error: function() {
                 bootbox.alert("Oops! Something went wrong. Please try again.", function() {
                   location.reload();
                 });
               }});
      return false;
    });

    $('.resume .remove-link a').click(function() {
      var form = fromPausingElementFind(this, '.form-selection form');
      var url = $(this).attr('href');
      var order_id = form.closest("tr[data-order-id]").attr('data-order-id');
      $.ajax({ type: 'POST',
               dataType: 'html',
               url: url,
               success: function(data){
                 reload_pause_details(order_id, data);
               },
               error: function() {
                 bootbox.alert("Oops! Something went wrong. Please try again.", function() {
                   location.reload();
                 });
               }});
      return false;
    });

    $('.pause .form-selection :submit').click(function() {
      var form = fromPausingElementFind(this, '.form-selection form');
      var url  = form.attr('action');
      var date = form.find('select :selected').val();
      var order_id = form.closest('.pausing').attr('data-order-id');

      $(this).attr('disabled', true);

      $.ajax({
        type: 'PUT',
        dataType: 'html',
        url: url,
        data: $.param({ date: date }),
        success: function(data){
          reload_pause_details(order_id, data);
        },
        error: function() {
          bootbox.alert("Oops! Something went wrong. Please try again.", function() {
            location.reload();
          });
        }});

      return false;
    });

    $('.resume .form-selection :submit').click(function() {
      var form = fromPausingElementFind(this, '.form-selection form');
      var url  = form.attr('action');
      var date = form.find('select :selected').val();
      var order_id = form.closest('.pausing').attr('data-order-id');

      $(this).attr('disabled', true);

      $.ajax({
        type: 'PUT',
        dataType: 'html',
        url: url,
        data: $.param({ date: date }),
        success: function(data){
          reload_pause_details(order_id, data);
        },
        error: function() {
          bootbox.alert("Oops! Something went wrong. Please try again.", function() {
            location.reload();
          });
        }});

      return false;
    });

    $('.resulting-link a').click(function() {
      fromPausingElementFind(this, '.resulting-link').hide();
      fromPausingElementFind(this, '.form-selection').css('display', 'inline-block');
      fromPausingElementFind(this, '.remove-link').css('display', 'inline-block');
      return false;
    });
  }

  order_pause_init();

  function reload_pause_details(order_id, data) {
    $('#order_' + order_id + '_details').html(data);
    order_pause_init();

    reload_activities();
  }

  function reload_activities() {
    var customer_id = $("#customer-details .customer-name").data("customer-id");

    $.get("/distributor/customers/" + customer_id + "/activity", function(data) {
      $("#activities").html(data).
        closest("#activity-section").slideDown(); // make sure it is visible if first item
    });
  }

  function fromPausingElementFind(startElement, findName) {
    return $(startElement).closest('.info-controller').find(findName);
  }

  $("#customer_override_default_balance_threshold").click(function(){
    if($("#balance_threshold").is(":visible")) {
      $("#customer_override_balance_threshold").val('0.00');
      $("#balance_threshold").hide('highlight');
    } else {
      $("#balance_threshold").show('highlight');
    }
  });

  var phone_inputs = $('form input[type="tel"]').not('.optional');
  if (phone_inputs.length > 1) {
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

    phone_inputs.keyup(update_phone_inputs_style);
    update_phone_inputs_style();
  }

  $("#export_customer_details").click(function(){
    if ($("#customer-details #section-one").length) {
      var customer = $("#customer-details #section-one .customer-badge").parent();
      var recipient_ids = customer.find('.customer-name').data('customer-id');
    } else {
      var recipient_ids = $('#customers .select_one:checked').map(function() {
        return this.id;
      }).get().join(",");
    }

    $("#export_recipient_ids").val(recipient_ids);
    $("#export_customer_details_form").submit();
  });

  //transaction customers count tooltip
  $('#transactional_customer_count').tooltip({placement: "right", html: true})
});

$(function() {
  var order_pause_init = function() {
    $('.initial-link a').click(function() {
      fromPausingElementFind(this, '.initial-link').hide();
      fromPausingElementFind(this, '.form-selection').show();
      return false;
    });

    $('.cancel-link a').click(function() {
      fromPausingElementFind(this, '.form-selection').hide();

      var resulting_link = fromPausingElementFind(this, '.resulting-link');

      if(resulting_link.data('date')) {
        resulting_link.show();
      }
      else {
        fromPausingElementFind(this, '.initial-link').show();
      }

      return false;
    });

    $('.remove-link a').click(function() {
      fromPausingElementFind(this, '.form-selection').hide();
      fromPausingElementFind(this, '.remove-link').hide();
      fromPausingElementFind(this, '.initial-link').show();
      return false;
    });

    $('.pause .remove-link a').click(function() {
      var resume = $(this).closest('.pausing').find('.resume');
      resume.hide();
      resume.find('.initial-link').show();
      resume.find('.form-selection').hide();
      resume.find('.remove-link').hide();
      resume.find('.resulting-link').hide();

      var form = fromPausingElementFind(this, '.form-selection form');
      var url = $(this).attr('href');
      var order_id = form.closest("tr[data-order-id]").attr('data-order-id');
      $.ajax({ type: 'POST',
               dataType: 'html',
               url: url,
               success: function(data){
                 reload_pause_details(order_id, data);
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
        }});

      return false;
    });

    $('.resulting-link a').click(function() {
      fromPausingElementFind(this, '.resulting-link').hide();
      fromPausingElementFind(this, '.form-selection').show();
      fromPausingElementFind(this, '.remove-link').show();
      return false;
    });
  }

  order_pause_init();

  function reload_pause_details(order_id, data) {
    $('#order_' + order_id + '_details').html(data);
    order_pause_init();
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
});

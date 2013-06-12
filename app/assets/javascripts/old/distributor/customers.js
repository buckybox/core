$(function() {

  //////////////////////////////////////////////////////////////////////////////
  // Checkbox selector
  //

  var select_one = function() {
    var email_actions = $('#action-buttons .email-actions');

    if ($('.select_one:checked').length === 0) {
      $('#select_all').prop("indeterminate", false).attr('checked', false);
      if (email_actions.hasClass('list-view'))
        email_actions.fadeOut();

    } else if ($('.select_one:not(:checked)').length === 0) {
      $('#select_all').prop("indeterminate", false).attr('checked', true);
      email_actions.fadeIn().css('display', 'inline-block');

    } else {
      $('#select_all').prop("indeterminate", true);
      email_actions.fadeIn().css('display', 'inline-block');
    }
  };

  $('.select_one').change(select_one);
  select_one(); // init master checkbox state on page refresh

  var select_all = function(value) {
    $('#select_all').prop("indeterminate", false).prop('checked', value);
    $('.select_one').attr('checked', $('#select_all').is(':checked'));
    select_one();
  };

  $('#select_all').closest('button').click(function() { select_all(!$('#select_all').is(':checked')); });
  $('#select_all').click(function() { select_all(!$('#select_all').is(':checked')); }); // Chrome hack

  $('#select_all-all').click(function() { select_all(true); });
  $('#select_all-none').click(function() { select_all(false); });

  //////////////////////////////////////////////////////////////////////////////
  // Email modal
  //

  var modal = $('#sendEmail.modal');
  var popovers = modal.find('[data-toggle="popover"]');

  $("#distributor_customers_email").click(function() {
    // set modal contents
    if ($("#customer-details #section-one").length) {
      var customer = $("#customer-details #section-one .customer-name")
      var recipients = customer.text();
      var recipient_ids = customer.data('customer-id');

    } else {
      var customers = $('#customers .select_one:checked');
      var max_customers = 3;
      var first_customers = customers.slice(0, max_customers);

      var recipients = first_customers.map(function() {
        return $("#" + this.id).closest('tr').find('.customer-name').text();
      }).get().join(', ');

      var recipient_ids = customers.map(function() {
        return this.id;
      }).get().join(',');

      var other_customers = customers.length - max_customers;
      if (other_customers > 0) {
        recipients += " and " + other_customers + " other" + (other_customers == 1 ? "" : "s");
      }
    }

    modal.find('.recipients').text(recipients);

    popovers.popover(); // enable popovers
    modal.find('.alert').hide();

    // set hidden fields
    $('#recipient_ids').val(recipient_ids);

    // set up event handlers
    modal.find('.delete-template').click(function() {
      var current_template = $(this).closest('.accordion-group').find('.collapse');

      current_template.on('hidden', function() {
        $(this).closest('.accordion-group').remove(); // remove from DOM

        var templates = modal.find('.accordion-group .collapse');
        templates.first().collapse('show');
      });

      current_template.collapse('hide');
    });

    modal.find('.accordion-toggle').click(function() {
      var clicked_template = $(this).closest('.accordion-group').find('.collapse');
      var other_templates = modal.find('.accordion-group .collapse.in').not(clicked_template);
      other_templates.collapse('hide');

      if (clicked_template.hasClass('in')) return false; // don't collapse it
    });

    modal.find('.collapse').on('show', function() {
      // hide/show the delete button
      var old_selected_email_template = $("#email_template_" + $('#selected_email_template_id').val());
      old_selected_email_template.closest('.accordion-group').find('.delete-template').addClass('hidden');
      $(this).closest('.accordion-group').find('.delete-template').removeClass('hidden');

      // set the current template ID
      var selected_email_template = $(this).closest('.accordion-group').find('.accordion-toggle');
      var selected_email_template_id = selected_email_template.prop('href').split('#email_template_')[1];
      $('#selected_email_template_id').val(selected_email_template_id);
    });

    // form events
    var submit_button = modal.find('input[type="submit"]');
    modal.find('form')
      .bind("ajax:beforeSend", function() {
        submit_button.button('loading');
        $(this).find('.alert-error').hide();
      })
      .bind("ajax:success", function(xhr, data, status) {
        location.reload();
      })
      .bind("ajax:error", function(xhr, data, status) {
        submit_button.button('reset');
        $(this).find('.alert-error').html(data.responseText).show();
      });

    // finally reveal the modal
    modal.modal('show');
  });

  modal.on('hide', function() {
    // cleanup
    popovers.popover('hide');
  });

  //////////////////////////////////////////////////////////////////////////////
  // Orders management
  //

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
});

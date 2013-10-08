$(function() {

  // Allow to hide (and not close aka delete Bootstrap alerts)
  $("[data-hide]").on("click", function(){
      $(this).closest("." + $(this).attr("data-hide")).hide();
  });

  //////////////////////////////////////////////////////////////////////////////
  // Checkbox selector
  //

  var select_one = function() {
    var conditional_actions = $('.action-buttons .conditional-actions');

    if ($('.select_one:checked').length === 0) {
      $('#select_all').prop("indeterminate", false).prop('checked', false);

    } else if ($('.select_one:not(:checked)').length === 0) {
      $('#select_all').prop("indeterminate", false).prop('checked', true);
      conditional_actions.fadeIn().css('display', 'inline-block');

    } else {
      $('#select_all').prop("indeterminate", true);
      conditional_actions.fadeIn().css('display', 'inline-block');
    }
  };

  $('.select_one').change(select_one).trigger('change');

  var select_all = function(value) {
    $('#select_all').prop('indeterminate', false).prop('checked', value);
    $('.select_one').prop('checked', value);
    select_one();
  };

  $('#select_all').closest('button').click(function() { select_all(!$('#select_all').is(':checked')); });
  $('#select_all').click(function() { select_all(!$('#select_all').is(':checked')); }); // Chrome hack

  $('#select_all-all').click(function() { select_all(true); });
  $('#select_all-none').click(function() { select_all(false); });
  $('#select_all-inverse').click(function() {
    $('.select_one').each(function() {
      $(this).prop('checked', !$(this).prop('checked'));
    });
    select_one();
  });

  //////////////////////////////////////////////////////////////////////////////
  // Email modal
  //

  var send_email_modal = $('#distributor_send_email.modal');

  var template_link_handler = function() {
    var current_link = $(this);
    var id = -1;

    send_email_modal.find('.template-link').each(function(index) {
      if ($(this)[0] == current_link[0]) {
        id = index;
        return false;
      }
    });

    $('#selected_email_template_id').val(id);

    send_email_modal.find('.template-link-action').show();

    send_email_modal.find('.template-link a').removeClass('selected');
    $(this).find('a').addClass('selected');

    $("#email_template_subject").val(current_link.find('.subject').html());
    $("#email_template_body").val(current_link.find('.body').html());
  };

  var show_error = function(message) {
    send_email_modal.find('form .alert-error .message').html(message).parent().show();
  };

  var show_success = function(message) {
    send_email_modal.find('form .alert-success .message').html(message).parent().show();
  };

  var update_template_link_attributes = function(template_link) {
    template_link.find('a span').text($("#email_template_subject").val());
    template_link.find('.subject').html($("#email_template_subject").val());
    template_link.find('.body').html($("#email_template_body").val());
  }

  var selected_email_template_link = function() {
    var template_link = null;
    var id = $('#selected_email_template_id').val();

    send_email_modal.find('.template-link').each(function(index) {
      if (index == id) {
        template_link = $(this);
        return false;
      }
    });

    return template_link;
  };

  var commit_button = send_email_modal.find('[type="submit"][name="commit"]');
  commit_button.click(function() {
    $(this).data("hide-info", true).button("loading");
  });

  send_email_modal.find('form')
    .bind("ajax:beforeSend", function() {
      commit_button.prop("disabled", true);
      $("#email_template_subject").prop("disabled", true);
      $("#email_template_body").prop("disabled", true);

      $(this).find('.alert').hide();

      if (commit_button.data("hide-info")) {
        commit_button.data("hide-info", false);
      } else {
        $(this).find('.alert-info').show();
      }
    })
    .bind("ajax:complete", function() {
      $(this).find('.alert-info').hide();

      $("#link_action").val("");

      commit_button.prop("disabled", false);
      $("#email_template_subject").prop("disabled", false);
      $("#email_template_body").prop("disabled", false);
    })
    .bind("ajax:success", function(xhr, data, status) {
      if (!data) {
        show_error("Oops!");

      } else if (data.send) {
        location.reload();

      } else if (data.update) {
        update_template_link_attributes(selected_email_template_link());

        show_success(data.message);
      } else if (data['delete']) {
        // hide template contextual actions
        send_email_modal.find('.template-link-action').hide();

        // remove template from list
        selected_email_template_link().remove();

        // hide divider if no templates remaining
        if (send_email_modal.find('.template-link').length == 0) {
          send_email_modal.find('.divider.templates').hide();
        }

        // reset selected template ID
        $('#selected_email_template_id').val("-1");

        // reset text fields
        $("#email_template_subject").val("");
        $("#email_template_body").val(
          $("#email_template_body").data("default-value")
        );

        show_success(data.message);
      } else if (data.save) {
        send_email_modal.find('.divider.templates').show();

        // clone the new template link
        var new_template_link_template = send_email_modal.find('.new-template-link');
        new_template_link_template.before(new_template_link_template[0].outerHTML);

        // update template link attributes and reveal it
        var new_template_link = send_email_modal.find('.new-template-link').first();
        update_template_link_attributes(new_template_link);
        new_template_link.removeClass('new-template-link hide').addClass('template-link');

        // set up click handler
        new_template_link.click(template_link_handler);
        new_template_link.trigger('click');

        show_success(data.message);
      } else {
        show_success(data.message);
      }
    })
    .bind("ajax:error", function(xhr, data, status) {
      commit_button.button('reset');
      show_error(JSON.parse(data.responseText).message);
    });

  send_email_modal.on('show', function() {
    // set modal contents
    if ($("#customer-details #section-one").length) {
      var customer = $("#customer-details #section-one .customer-badge").parent();
      var recipients = customer.html();
      var recipient_ids = customer.find('.customer-name').data('customer-id');

    } else {
      var customers = $('.select_one:checked');
      var max_customers = 3;
      var first_customers = customers.slice(0, max_customers);

      var recipients = first_customers.map(function() {
        return $(this).closest('.customer-row').find('.customer-badge').parent().html();
      }).get().join(', ');

      var recipient_ids = customers.map(function() {
        return $(this).data('customer-id');
      }).get().join(',');

      var other_customers = customers.length - max_customers;
      if (other_customers > 0) {
        recipients += " and " + other_customers + " other" + (other_customers == 1 ? "" : "s");
      }
    }

    console.log("IDS:" + recipient_ids);
    $('#recipient_ids').val(recipient_ids);
    send_email_modal.find('.recipients').html(recipients);
    send_email_modal.find('.template-link').click(template_link_handler);
    send_email_modal.find('.alert').hide();
    $('#distributor_send_email_merge_tags').popover(); // enable popover
  });


  $("#distributor_copy_email.modal").on("show", function() {
    var customers = $('.select_one:checked').closest('.customer-row').find('.customer-name');

    var emails = customers.map(function() {
      return $(this).data('customer-email');
    }).get().join(', ');

    var list = $(this).find('textarea');
    list.val(emails);

    list.focus(function() { $(this).select(); });
    list.click(function() { $(this).select(); });
  });

});


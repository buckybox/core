$(function() {
  if($('.order').length > 0) {
    order_init();

    $('.order .dislikes_input').show();
    $('.order .dislikes_input select').select2();
    $('.order .dislikes_input').hide();

    $('.order .likes_input').show();
    $('.order .likes_input select').select2();
    $('.order .likes_input').hide();
  }

  if($('.pause').length > 0) {
    $('.order .date_picker').dateinput({ format: 'yyyy-mm-dd' });
  }

  $('.order select.box').change(function() {
    var box_id = $(this).val();
    var current_order = $(this).closest('.order');

    if(box_id) {
      order_check_box(box_id, current_order);
      update_customer_box_extras(current_order);
    }
    else {
      current_order.find('.dislikes_input').hide();
      current_order.find('.likes_input').hide();
    }
  });

  $('.order select.frequency').change(function() {
    day_display($(this));
  });

  $('.order .dislikes_input').change(function() {
    var current_order  = $(this).closest('.order');
    var likes_input    = current_order.find('.likes_input');
    var dislikes_input = current_order.find('.dislikes_input');

    disable_the_others_options(dislikes_input, likes_input);

    if(!dislikes_input.is(':hidden') && dislikes_input.find('option:selected').length > 0) {
      likes_input.show();
    }
    else {
      likes_input.find('option:selected').removeAttr('selected');
      likes_input.find('select').trigger('liszt:updated');
      likes_input.hide();
    }
  });

  $('.order .likes_input').change(function() {
    var current_order  = $(this).closest('.order');
    var likes_input    = current_order.find('.likes_input');
    var dislikes_input = current_order.find('.dislikes_input');

    disable_the_others_options(likes_input, dislikes_input);

    if(dislikes_input.find('option:selected').length == 0) {
      likes_input.find('option:selected').each(function() {
        $(this).removeAttr('selected');
        likes_input.hide();

        likes_input.find('select').trigger("liszt:updated");
      });
    }
  });

  $(".order .include_extras").change(function() {
    var current_order = $(this).closest('.order');
    update_order_extras_collection(current_order);
  });

  $(".order input[type=submit]").click(function() {
    var current_order = $(this).closest('.order');
    var include_extras = current_order.find('#order_include_extras').prop('checked');

    if (!include_extras) {
      current_order.find(".extras input[type=number]").val(0);
    }

    return true;
  });
});

function disable_the_others_options(affecting_input, effected_input) {
  affecting_input.find('option:selected').each(function() {
    counter = effected_input.find("option[value='" + $(this).val() + "']");
    counter.attr('disabled', 'disabled');
    counter.removeAttr('selected');
  });

  effected_input.find('select').trigger("liszt:updated");
}

function order_init() {
  $('.order').each( function() {
    var box_id = $(this).find('select.box').val();

    day_display($(this).find('select.frequency'));
    update_order_extras_collection($(this));

    if(box_id) { order_check_box(box_id, $(this)); }
  });
}

function day_display(frequency_selector) {
  var days = frequency_selector.closest('.order').find('.days');
  var frequency = frequency_selector.val();

  (frequency === 'single' ? days.hide() : days.show() );
}

function order_check_box(box_id, current_order) {
  var is_distributor = current_order.find('#is_distributor').val();
  var uri_root = (is_distributor ? 'distributor' : 'customer');
  var path_root = $(location).attr('pathname').split('/')[1];

  $.ajax({
    type: 'GET',
    dataType: 'json',
    url: '/' + path_root + '/boxes/' + box_id + '.json',
    success: function(data) {
      if(data['dislikes']) {
        current_order.find('.dislikes_input').show();
      }
      else {
        current_order.find('.dislikes_input').hide();
      }

      if(data['likes'] && current_order.find('.dislikes_input').find('option:selected').length > 0) {
        current_order.find('.likes_input').show();
      }
      else {
        current_order.find('.likes_input').hide();
      }
    }
  });
}

function update_order_extras_collection(current_order) {
  var include_extras = current_order.find("#order_include_extras").prop("checked");

  if (include_extras) {
    current_order.find(".extras").show();
  } 
  else {
    current_order.find(".extras").hide();
  }
};

function update_customer_box_extras(current_order) {
  var box_id = current_order.find('select.box').val();
  var path_root = $(location).attr('pathname').split('/')[1];

  var url = '/' + path_root;
  if(typeof current_account_id != 'undefined') { url += '/accounts/' + current_account_id; }
  url += '/boxes/' + box_id + '/extras';

  $.get(url, function(data) {
    current_order.find(".order_extras").html(data);
  });
};

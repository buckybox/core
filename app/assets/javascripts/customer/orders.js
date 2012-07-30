// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

$(function() {
  if($('.customer_order').length > 0) { customer_order_init(); }

  if($('.customer_pause').length > 0) {
    $('.date_picker').dateinput({ format: 'yyyy-mm-dd' });
  }

  $('.customer_order #customer_order_box_id').change(function() {
    var box_id = $(this).val();
    var current_order = $(this).closest('.customer_order');

    if(box_id) {
      customer_check_box(box_id, current_order);
    }
    else {
      current_order.find('#dislikes_input').hide();
      current_order.find('#likes_input').hide();
    }
  });

  $('.customer_order #order_frequency').change(function() {
    day_display($(this));
  });

  $('.customer_order #dislikes_input').change(function() {
    likes_input = $('#likes_input');
    dislikes_input = $('#dislikes_input');

    if(!dislikes_input.is(':hidden') && dislikes_input.find('option:selected').length > 0) {
      likes_input.show();
    }
    else {
      likes_input.find('option:selected').attr('selected', false);
      likes_input.find('select').trigger('liszt:updated');
      likes_input.hide();
    }
  });
});

function customer_order_init() {
  $('.customer_order').each( function() {
    var box_id = $('#customer_order_box_id', this).val();

    day_display($('.customer_order #order_frequency'));

    if(box_id) { customer_check_box(box_id, $(this)); }
  });
}

function day_display(frequency_selector) {
  var days = frequency_selector.closest('.customer_order').find('#days');
  var frequency = frequency_selector.val();

  (frequency === 'single' ? days.hide() : days.show() );
}

function customer_check_box(box_id, current_order) {
  $.ajax({
    type: 'GET',
    url: '/customer/boxes/' + box_id + '.json',
    dataType: 'json',
    success: function(data) {
      if(data['dislikes']) {
        current_order.find('#dislikes_input').show();
      }
      else {
        current_order.find('#dislikes_input select').hide();
      }

      if(data['likes'] && current_order.find('#dislikes_input').find('option:selected').length > 0) {
        current_order.find('#likes_input').show();
      }
      else {
        current_order.find('#likes_input select').hide();
      }
    }
  });
}

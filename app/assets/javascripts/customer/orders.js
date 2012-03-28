// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

$(function() {
  if($('.customer_order').length > 0) { customer_order_init(); }

  if($('.customer_pause').length > 0) {
    $('.date_picker').dateinput({ format: 'yyyy-mm-dd', min: -1 });
  }

  $('.customer_order #order_box_id').change(function() {
    var box_id = $(this).val();
    var current_order = $(this).closest('.customer_order');

    if(box_id) {
      customer_check_box(box_id, current_order);
    }
    else {
      current_order.find('#likes_input').hide();
      current_order.find('#dislikes_input').hide();
    }
  });

  $('.customer_order #order_frequency').change(function() {
    var days = $(this).closest('.customer_order').find('#days');

    if($(this).val() === 'single') {
      days.hide();
    }
    else {
      days.show();
    }
  });
});

function customer_order_init() {
  $('.customer_order').each( function() {
    var box_id = $('#order_box_id', this).val();

    if(box_id) { customer_check_box(box_id, $(this)); }
  });
}

function customer_check_box(box_id, current_order) {
  $.ajax({
    type: 'GET',
    url: '/customer/boxes/' + box_id + '.json',
    dataType: 'json',
    success: function(data) {
      if(data['likes']) {
        current_order.find('#likes_input').show();
      }
      else {
        current_order.find('#likes_input').hide();
      }

      if(data['dislikes']) {
        current_order.find('#dislikes_input').show();
      }
      else {
        current_order.find('#dislikes_input').hide();
      }
    }
  });
}

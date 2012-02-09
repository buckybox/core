// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

$(function() {
  if($('.customer_order').length > 0) { customer_order_init(); }

  $('.customer_order #order_box_id').change(function() {
    var order_id = $(this).first().parent().parent().parent().children('#order_id').val();
    var box_id = $(this).val();

    var order_css_id = '#edit_order_' + order_id;

    $(order_css_id + ' #order_likes').val('');
    $(order_css_id + ' #order_dislikes').val('');

    if(box_id) {
      customer_check_box(order_id, box_id);
    }
    else {
      $(order_css_id + ' #likes_input').hide();
      $(order_css_id + ' #dislikes_input').hide();
    }
  });
});

function customer_order_init() {
  $('.customer_order').each( function() {
    var order_id = $('#order_id', this).val();
    var box_id = $('#order_box_id', this).val();

    if(order_id && box_id) { customer_check_box(order_id, box_id); }
  });
}

function customer_check_box(order_id, box_id) {
  $.ajax({
    type: 'GET',
    url: '/customer/order/' + order_id + '/box/' + box_id + '.json',
    dataType: 'json',
    success: function(data) {
      var order_css_id = '#edit_order_' + data['order']['id'];

      if(data['box']['likes']) {
        $(order_css_id + ' #likes_input').show();
      }
      else {
        $(order_css_id + ' #likes_input').hide();
      }

      if(data['box']['dislikes']) {
        $(order_css_id + ' #dislikes_input').show();
      }
      else {
        $(order_css_id + ' #dislikes_input').hide();
      }
    }
  });
}

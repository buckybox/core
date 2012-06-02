// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

$(function() {
  if($('#distributor_order').length > 0) { distributor_order_init(); }

  if($('#distributor_order').length > 0) {
    $('.date_picker').dateinput({ format: 'yyyy-mm-dd' });
  }

  $('#distributor_order #distributor_order_box_id').change(function() {
    var box_id = $(this).val();

    $('#order_likes').val('');
    $('#order_dislikes').val('');

    if(box_id) {
      distributor_check_box(box_id);
    }
    else {
      $('#likes_input').hide();
      $('#dislikes_input').hide();
    }
  });

  $('#distributor_order #order_frequency').change(function() {
    if($(this).val() === 'single') {
      $('#distributor_order #days').hide();
    }
    else {
      $('#distributor_order #days').show();
    }
  });
});

function distributor_order_init() {
  var box_id = $('#distributor_order_box_id').val();
  var frequency = $('#order_frequency').val();

  if(box_id) { distributor_check_box(box_id); }
  if(frequency && (frequency !== 'single')) { $('#days').show(); }
}

function distributor_check_box(box_id) {
  $.ajax({
    type: 'GET',
    url: '/distributor/boxes/' + box_id + '.json',
    dataType: 'json',
    success: function(data) {
      if(data['likes']) {
        $('#likes_input').show();
      }
      else {
        $('#likes_input').hide();
      }

      if(data['dislikes']) {
        $('#dislikes_input').show();
      }
      else {
        $('#dislikes_input').hide();
      }
    }
  });
}

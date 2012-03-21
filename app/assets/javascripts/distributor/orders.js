// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

$(function() {
  if($('#distributor_order').length > 0) { distributor_order_init(); }

  $('#distributor_order #order_box_id').change(function() {
    var distributor_id = $('#distributor_id').val();
    var box_id = $(this).val();

    $('#order_likes').val('');
    $('#order_dislikes').val('');

    if(box_id) {
      distributor_check_box(distributor_id, box_id);
    }
    else {
      $('#likes_input').hide();
      $('#dislikes_input').hide();
    }
  });

  $('#distributor_order #order_frequency').change(function() {
    if($(this).val() === 'single') {
      $('#days').hide();
    }
    else {
      $('#days').show();
    }
  });
});

function distributor_order_init() {
  var distributor_id = $('#distributor_id').val();
  var box_id = $('#order_box_id').val();
  var frequency = $('#order_frequency').val();

  if(distributor_id && box_id) { distributor_check_box(distributor_id, box_id); }
  if(frequency && (frequency !== 'single')) { $('#days').show(); }
}

function distributor_check_box(distributor_id, box_id) {
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

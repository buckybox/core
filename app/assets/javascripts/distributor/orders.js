// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

$(function() {
  $('#order_box_id').change(function() {
    distributor_id = $('#distributor_id').val();
    box_id = $(this).val();
    
    if(box_id) {
      $.ajax({
        type: 'GET',
        url: '/distributors/' + distributor_id + '/boxes/' + box_id + '.json',
        dataType: 'json',
        success: function(data) {
          console.info(data);
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
    else {
      $('#likes_input').hide();
      $('#dislikes_input').hide();
    }
  });
});

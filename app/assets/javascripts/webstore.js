$(function() { 
  $('#buy_extra_include_extras').change(function() {
    if($(this).is(':checked')) {
      $('#webstore_extras').show();
    }
    else {
      $('#webstore_extras').hide();
    }
  });

  if($('.webstore-customise').length > 0) {
    dislikes = $('.webstore-customise .dislikes_input');
    likes = $('.webstore-customise .likes_input');

    dislikes.show();
    dislikes.find('select').chosen();

    likes.show();
    likes.find('select').chosen();
    likes.hide();
  }
});

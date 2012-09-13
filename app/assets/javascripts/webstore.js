$(function() { 
  $('#buy_extra_include_extras').change(function() {
    if($(this).is(':checked')) {
      $('#webstore_extras').show();
    }
    else {
      $('#webstore_extras').hide();
    }
  });

  if($('#webstore-customise').length > 0) {
    var dislikes = $('#webstore-customise .dislikes_input');
    var likes = $('#webstore-customise .likes_input');

    dislikes.find('select').chosen();
    likes.find('select').chosen();
    likes.hide();
    $('#webstore-customisations').hide();

    $('#webstore_order_customise_costomise').click(function() {
      checkbox_toggle(this, $('#webstore-customisations'));
    });

    dislikes.change(function() {
      var likes_input    = $('#webstore-customisations').find('.likes_input');
      var dislikes_input = $(this);

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

    likes.change(function() {
      var likes_input    = $(this);
      var dislikes_input = $('#webstore-customisations').find('.dislikes_input');

      disable_the_others_options(likes_input, dislikes_input);

      if(dislikes_input.find('option:selected').length == 0) {
        likes_input.find('option:selected').each(function() {
          $(this).removeAttr('selected');
          likes_input.hide();

          likes_input.find('select').trigger("liszt:updated");
        });
      }
    });
  }

  if($('#webstore-extras').length > 0) {
    var extras_input = $('#webstore-extras select');

    extras_input.chosen();
    $('#webstore-extras-options').hide();

    extras_input.change(function() {
      var extras_input = $(this);
      var selected_extra = $(extras_input.find('option:selected')[0]);
      var extra_id = selected_extra.val();
      var quantity_input = $('#webstore_order_extras_' + extra_id);

      quantity_input.val(1);
      quantity_input.closest('tr').show();

      selected_extra.attr('disabled', 'disabled');
      selected_extra.removeAttr('selected');
      selected_extra.closest('select').trigger("liszt:updated");

      total_options = extras_input.find('option').length - 1;
      disabled_options = extras_input.find('option:disabled').length;

      if(total_options == disabled_options) { extras_input.closest('tr').hide(); }
    });
  }
});

function checkbox_toggle(checkbox, div) {
  if(checkbox.checked) {
    div.show();
  }
  else {
    div.hide();
  }
}

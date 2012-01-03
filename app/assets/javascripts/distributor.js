$(function() {
  $('#delivery-listings #missed').click(function() {
     $('#delivery-listings .flyout').toggle();
     return false;
  });

  $('#delivery-listings #all').change(function() {
    ckbxs = $('#delivery-listings .data-listings input[type=checkbox]');

    if($(this).is(':checked')) {
      ckbxs.prop("checked", true);
    }
    else {
      ckbxs.prop("checked", false);
    }

    return false;
  });
});

$(function() {
  $('#delivery-listings #missed').click(function() {
     $('#delivery-listings .flyout').toggle();
     return false;
  });

  $('#delivery-listings #all').change(function() {
    ckbxs = $('#delivery-listings .data-listings input[type=checkbox]');

    if($(this).is(':checked')) { ckbxs.prop("checked", true); }
    else { ckbxs.prop("checked", false); }

    return false;
  });
});

function updateDeliveryStatus(id, distributor_id, checked_deliveries) {
  ckbx_ids = $.map(checked_deliveries, function(ckbx) { return $(ckbx).data('delivery'); });

  $.ajax({
    type: 'POST',
    url: '/distributors/' + distributor_id + '/deliveries/update_status.json',
    dataType: 'json',
    data: $.param({
      'deliveries': ckbx_ids,
      'status': id
    })
  });

  $.each(checked_deliveries, function(index, ckbx) { 
    holder = $(ckbx).parent().parent();

    if(id === 'delivered') {
      holder.addClass('delivered');
      holder.removeClass('missed');
    }
    else {
      holder.addClass('missed');
      holder.removeClass('delivered');
    }
  });
}

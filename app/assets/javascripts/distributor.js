$(function() {
  $('.data-listings').click(function() {
    checkbox = $('input[type=checkbox]', this);

    if(checkbox.is(':checked')) {  checkbox.prop('checked', false); }
    else { checkbox.prop('checked', true); }

    return false;
  });

  $('#delivery-listings #missed').click(function() {
     $('#delivery-listings .flyout').toggle();
     return false;
  });

  $('#delivery-listings #all').change(function() {
    checked_deliveries = $('#delivery-listings .data-listings input[type=checkbox]');

    if($(this).is(':checked')) { checked_deliveries.prop('checked', true); }
    else { checked_deliveries.prop('checked', false); }

    return false;
  });

  $('#delivery-listings #delivered, #delivery-listings #pending').click(function() {
    id = $(this).attr('id');
    distributor_id = $('#delivery-listings').data('distributor');
    checked_deliveries = $('#delivery-listings .data-listings input[type=checkbox]:checked');

    updateDeliveryStatus(id, distributor_id, checked_deliveries);

    checked_deliveries.prop('checked', false);

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

    if(id == 'pending') {
      holder.removeClass('delivered cancelled missed');
    }
    else if(id == 'delivered') {
      holder.addClass('delivered');
      holder.removeClass('cancelled missed');
    }
  });
}

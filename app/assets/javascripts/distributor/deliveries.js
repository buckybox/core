// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

$(function() {
  $("#calendar-navigation").jScrollPane();

  $('#delivery-listings #all').change(function() {
    var checked_deliveries = $('#delivery-listings .data-listings input[type=checkbox]');

    if($(this).is(':checked')) { checked_deliveries.prop('checked', true); }
    else { checked_deliveries.prop('checked', false); }

    return false;
  });

  $('#delivery-listings #delivered, #delivery-listings #pending').click(function() {
    var id = $(this).attr('id');
    var distributor_id = $('#delivery-listings').data('distributor');
    var checked_deliveries = $('#delivery-listings .data-listings input[type=checkbox]:checked');

    updateDeliveryStatus(id, distributor_id, checked_deliveries);

    checked_deliveries.prop('checked', false);
    $('#delivery-listings #all').prop('checked', false);

    return false;
  });

  $('#delivery-listings #missed').click(function() {
     $('#delivery-listings .flyout').toggle();
     return false;
  });

  $('#commit-missed').click(function() {
    var distributor_id = $('#delivery-listings').data('distributor');
    var checked_deliveries = $('#delivery-listings .data-listings input[type=checkbox]:checked');
    var missed_option = $('#missed-options input:radio[name=missed]:checked').val();
    var date = undefined;

    if(missed_option === 'rescheduled' || missed_option === 'repacked') {
      date = $('#date_' + missed_option).val();
    }

    updateDeliveryStatus(missed_option, distributor_id, checked_deliveries, date);

    checked_deliveries.prop('checked', false);
    $('#delivery-listings #all').prop('checked', false);
    $('#delivery-listings .flyout').toggle();

    return false;
  });
});

function updateDeliveryStatus(status, distributor_id, checked_deliveries, date) {
  var ckbx_ids = $.map(checked_deliveries, function(ckbx) { return $(ckbx).data('delivery'); });
  var data_hash = { 'deliveries': ckbx_ids, 'status': status };
  if(date) { data_hash['date'] = date; }

  $.ajax({
    type: 'POST',
    url: '/distributors/' + distributor_id + '/deliveries/update_status.json',
    dataType: 'json',
    data: $.param(data_hash)
  });

  $.each(checked_deliveries, function(index, ckbx) {
    holder = $(ckbx).parent().parent();

    if(status === 'pending') {
      holder.removeClass('delivered cancelled rescheduled repacked');
    }
    else if(status === 'delivered') {
      holder.addClass('delivered');
      holder.removeClass('cancelled rescheduled repacked');
    }
    else if(status === 'cancelled') {
      holder.addClass('cancelled');
      holder.removeClass('delivered rescheduled repacked');
    }
    else if(status === 'rescheduled') {
      holder.addClass('rescheduled');
      holder.removeClass('delivered cancelled repacked');
    }
    else if(status === 'repacked') {
      holder.addClass('repacked');
      holder.removeClass('delivered cancelled rescheduled');
    }
  });
}

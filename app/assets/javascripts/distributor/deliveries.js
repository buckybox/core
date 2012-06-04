// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

$(function() {
  var element = $('#calendar-navigation').jScrollPane();

  if(element) {
    var api = element.data('jsp');
    api.scrollToElement($('#scroll-to'), true);
  }

  $('.sortable').sortable({
    delay:250,
    placeholder:'ui-state-highlight',
    curser: 'move',
    opacity: 0.8,
    update: function() {
      $.ajax({
        type: 'post',
        data: $('#delivery_list').sortable('serialize'),
        dataType: 'json',
        url: '/distributor/deliveries/date/' +
          $('#delivery-listings').data('date') +
          '/reposition'
      })
    }
  });
  $('.sortable').disableSelection();

  $('#delivery-listings #all').change(function() {
    var checked_deliveries = $('#delivery-listings .data-listings input[type=checkbox]');

    if($(this).is(':checked')) { checked_deliveries.prop('checked', true); }
    else { checked_deliveries.prop('checked', false); }

    return false;
  });

  $('#delivery-listings #master-print').click(function () {
    var checked_packages = $('#delivery-listings .data-listings input[type=checkbox]:checked');
    var ckbx_ids = $.map(checked_packages, function(ckbx) { return $(ckbx).data('package'); });

    $.each(checked_packages, function(i, ckbx) {
      var holder = $(ckbx).parent().parent();

      holder.addClass('packed');
      holder.removeClass('unpacked');

      holder.find('.icon-packed').show();
      holder.find('.icon-unpacked').hide();
    });

    var form = $(this).parent().parent('form');

    $.each(ckbx_ids, function(index, package_id) {
      $("<input type='hidden'>").attr('name', 'packages[]').attr('value', package_id).appendTo(form);
    });

    checked_packages.prop('checked', false);
    $('#delivery-listings #all').prop('checked', false);
  });

  $('#delivery-listings #packing-export').click(function() {
    var checked_packages = $('#delivery-listings .data-listings input[type=checkbox]:checked');
    var ckbx_ids = $.map(checked_packages, function(ckbx) { return $(ckbx).data('package'); });

    var form = $(this).parent().parent('form');

    $.each(ckbx_ids, function(index, delivery_id) {
      $("<input type='hidden'>").attr('name', 'packages[]').attr('value', delivery_id).appendTo(form);
    });

    checked_packages.prop('checked', false);
    $('#delivery-listings #all').prop('checked', false);
  });

  $('#delivery-listings #delivery-export').click(function() {
    var checked_deliveries = $('#delivery-listings .data-listings input[type=checkbox]:checked');
    var ckbx_ids = $.map(checked_deliveries, function(ckbx) { return $(ckbx).data('delivery'); });

    var form = $(this).parent().parent('form');

    $.each(ckbx_ids, function(index, delivery_id) {
      $("<input type='hidden'>").attr('name', 'deliveries[]').attr('value', delivery_id).appendTo(form);
    });

    checked_deliveries.prop('checked', false);
    $('#delivery-listings #all').prop('checked', false);
  });

  $('#delivery-listings #delivered, #delivery-listings #pending, #delivery-listings #paied').click(function() {
    var distributor_id = $('#delivery-listings').data('distributor');
    var status = $(this).attr('id');
    var checked_deliveries = $('#delivery-listings .data-listings input[type=checkbox]:checked');

    updateDeliveryStatus(status, distributor_id, checked_deliveries);

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

    if(missed_option === 'reschedule' || missed_option === 'repack') {
      date = $('#date_' + missed_option).val();
    }

    updateDeliveryStatus(missed_option, distributor_id, checked_deliveries, date);

    checked_deliveries.prop('checked', false);
    $('#delivery-listings #all').prop('checked', false);
    $('#delivery-listings .flyout').toggle();

    return false;
  });

  $('.delivery-paid').click(function() {
    console.info('You Paid!');
    $.ajax({url: $(this).attr('href'), type: 'POST'});

    return false;
  });
});

function updateDeliveryStatus(status, distributor_id, checked_deliveries, date) {
  var ckbx_ids = $.map(checked_deliveries, function(ckbx) { return $(ckbx).data('delivery'); });
  var data_hash = { 'deliveries': ckbx_ids, 'status': status };
  if(date) { data_hash['date'] = date; }

  $.ajax({
    type: 'POST',
    url: '/distributor/deliveries/update_status.json',
    dataType: 'json',
    data: $.param(data_hash)
  });

  $.each(checked_deliveries, function(i, ckbx) {
    var holder = $(ckbx).parent().parent();

    var statuses = ['pending', 'delivered', 'cancelled', 'rescheduled', 'repacked'];
    statuses.splice(statuses.indexOf(status), 1);

    holder.addClass(status);
    holder.removeClass(statuses.join(' '));

    holder.find('.icon-' + status).show();
    $.each(statuses, function(j, hide_status) {
      holder.find('.icon-' + hide_status).hide();
    });
  });
}


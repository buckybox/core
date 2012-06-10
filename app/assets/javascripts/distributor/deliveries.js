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

  $('#route-controls #delivered, #missed-options a').click(function() {
    var distributor_id = $('#delivery-listings').data('distributor');
    var status = $(this).attr('id');
    var checked_deliveries = $('#delivery-listings .data-listings input[type=checkbox]:checked');

    if(status == 'payment-on-delivery' && status == 'undo-payment') {
      reverse_payment = (status == 'undo-payment');
      makePayments(distributor_id, checked_deliveries, reverse_payment);
    }
    else {
      updateDeliveryStatus(status, distributor_id, checked_deliveries);
    }

    checked_deliveries.prop('checked', false);
    $('#delivery-listings #all').prop('checked', false);

    return false;
  });

  $('#delivery-listings #more-delivery-options').click(function() {
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

function makePayments(distributor_id, checked_deliveries, reverse_payment) {
  var ckbx_ids = $.map(checked_deliveries, function(ckbx) { return $(ckbx).data('delivery'); });
  var data_hash = { 'deliveries': ckbx_ids, 'status': status };
  if(reverse_payment) { data_hash['reverse_payment'] = true; }

  $.ajax({
    type: 'POST',
    url: '/distributor/deliveries/make_payment.json',
    dataType: 'json',
    data: $.param(data_hash)
  });
}

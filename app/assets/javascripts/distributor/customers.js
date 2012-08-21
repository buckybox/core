$(function() {
  $('#more-transactions a').click(function() {
    $(this).hide();
    $('#more-transactions #ajax-loader').show();

    var account_id = $('#transactions').data('account');
    var offset = $('#transactions .transaction-data').length;

    $.ajax({
      type: 'GET',
      dataType: 'html',
      url: '/distributor/accounts/' + account_id + '/more_transactions/' + offset,
      success: function(data) {
        var transaction_table = $('#transactions');
        var more_link = transaction_table.find('tr:last');

        transaction_table.append(data);

        more_link.appendTo(transaction_table);
        $('#more-transactions #ajax-loader').hide();
        $('#more-transactions a').show();
        more_link.show();
      }
    });

    return false;
  });

  $('.initial-link a').click(function() {
    fromPausingElementFind(this, '.initial-link').hide();
    fromPausingElementFind(this, '.form-selection').show();
    return false;
  });

  $('.cancel-link a').click(function() {
    fromPausingElementFind(this, '.form-selection').hide();
    fromPausingElementFind(this, '.initial-link').show();
    return false;
  });

  $('.remove-link a').click(function() {
    fromPausingElementFind(this, '.form-selection').hide();
    fromPausingElementFind(this, '.remove-link').hide();
    fromPausingElementFind(this, '.initial-link').show();
    return false;
  });

  $('.pause .remove-link a').click(function() {
    resume = $(this).closest('.pausing').find('.resume');
    resume.hide();
    resume.find('.initial-link').show();
    resume.find('.form-selection').hide();
    resume.find('.remove-link').hide();
    resume.find('.resulting-link').hide();
    return false;
  });

  $('.form-selection :submit').click(function() {
    fromPausingElementFind(this, '.form-selection').hide();
    fromPausingElementFind(this, '.resulting-link').show();
    return false;
  });

  $('.pause .form-selection :submit').click(function() {
    resume = $(this).closest('.pausing').find('.resume');
    resume.show();
    return false;
  });

  $('.resulting-link a').click(function() {
    fromPausingElementFind(this, '.resulting-link').hide();
    fromPausingElementFind(this, '.form-selection').show();
    fromPausingElementFind(this, '.remove-link').show();
    return false;
  });
});

function fromPausingElementFind(startElement, findName) {
  return $(startElement).closest('.info-controller').find(findName);
}

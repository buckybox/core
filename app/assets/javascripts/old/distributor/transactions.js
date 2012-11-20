$(function(){
  function setup_page(){
    // Setup the default value
    if(!($.cookie("transaction_order") === 'date_processed' || $.cookie("transaction_order") === 'transaction_date')){
      $.cookie("transaction_order", 'date_processed', {path: '/'});
    };

    if($.cookie("transaction_order") === 'date_processed'){
      $('th.sort_header.transaction_date').addClass('disabled');
      $('th.sort_header.date_processed').removeClass('disabled');
    }else{
      $('th.sort_header.transaction_date').removeClass('disabled');
      $('th.sort_header.date_processed').addClass('disabled');
    }

    $('th.sort_header.date_processed').click(function(){
      var clicked = $(this);
      var account_id = $('#account-information').data('account_id');
      if(clicked.hasClass('disabled')){
        $.cookie("transaction_order", 'date_processed', {path: '/' });
        $.get("/" + $("#sortable_transactions").data("user") + "/accounts/" + account_id + "/transactions/" + $('#sortable_transactions table tr.transaction-data').size(), function(data){
          $('#sortable_transactions').html(data);
          setup_page();
        }, 'html');
      }
    });

    $('th.sort_header.transaction_date').click(function(){
      var clicked = $(this);
      var account_id = $('#account-information').data('account_id');
      if(clicked.hasClass('disabled')){
        $.cookie("transaction_order", 'transaction_date', {path: '/' });
        $.get("/" + $("#sortable_transactions").data("user") + "/accounts/" + account_id + "/transactions/" + $('#sortable_transactions table tr.transaction-data').size(), function(data){
          $('#sortable_transactions').html(data);
          setup_page();
        }, 'html');
      }
    });
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
          if ($('#transactions .transaction-data').length != offset){
            $('#more-transactions a').show();
            more_link.show();
          }
        }
      });

      return false;
    });
  }
  setup_page();

});

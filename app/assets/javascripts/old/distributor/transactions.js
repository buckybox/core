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
      var account_id = $('#account-information').data('account_id');
      var offset = $('#transactions .transaction-data').length;
      $.get("/" + $("#sortable_transactions").data("user") + "/accounts/" + account_id + "/transactions/" + $('#sortable_transactions table tr.transaction-data').size() + "/more", function(data){
        $('#sortable_transactions').html(data);
        setup_page();
      }, 'html');

      return false;
    });
  }
  setup_page();

});

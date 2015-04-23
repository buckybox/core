$(function(){
  function setup_page() {
    $('#more-transactions a').click(function() {
      $(this).hide();
      var account_id = $('#account-information').data('account-id');
      var offset = $('#transactions .transaction-data').length;
      $.get("/" + $("#sortable_transactions").data("user") + "/accounts/" + account_id + "/transactions/" + $('#sortable_transactions table tr.transaction-data').size() + "/more", function(data){
        $('#sortable_transactions').html(data);
        setup_page();
      }, 'html');

      return false;
    });
  };
  setup_page();
});


$(function(){
  // Setup the default value
  if(!($.cookie("transaction_order") === 'date_processed' || $.cookie("transaction_order") === 'transaction_date')){
    $.cookie("transaction_order", 'date_processed')
  };

  if($.cookie("transaction_order") === 'date_processed'){
    $('th.sort_header.transaction_date').addClass('disabled');
    $('th.sort_header.date_processed').removeClass('disabled');
  }else{
    $('th.sort_header.transaction_date').removeClass('disabled');
    $('th.sort_header.date_processed').addClass('disabled');
  }
});

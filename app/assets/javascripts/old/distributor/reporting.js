$(function(){
  $('.date_picker').dateinput({ trigger: true, format: 'dd-mmm-yyyy'});
  $('.date_picker').change(function(){
    $("#export_transactions").attr('href', $("#export_transactions").data('href') + $('.date_picker.start').val() + '/' + $('.date_picker.end').val());
    $("#export_customer_account_history_link").attr('href', $("#export_customer_account_history_link").data('href') + $('.date_picker.export_account_balance').val());
  });
});

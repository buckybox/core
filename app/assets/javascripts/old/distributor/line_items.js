$(function() {
  $('#stock-list-controls #submit-button').click(function() {
    $('#bulk-update').submit();
  });

  $('#bulk-update input').keyup(function() {
    stock_item_input(this);
  });

  $('#bulk-update .remove').click(function() {
    input_element = $(this).closest('tr').find('input')[0];
    $(input_element).val('');
    stock_item_input(input_element);
    return false;
  });
});

function stock_item_input(element) {
  warning        = $(element).closest('tr').find('.label-warning');
  remove         = $(element).closest('tr').find('.remove');
  original_value = $(element).data('original-value');
  current_value  = $(element).val();

  console.info(warning);
  console.info(remove);
  console.info(original_value);
  console.info(current_value);

  if(current_value != original_value) {
    warning.show();
  }
  else {
    warning.hide();
  }

  if(current_value.length > 0) {
    remove.show();
  }
  else {
    remove.hide();
  }
}

$(function() {
  $('#stock-list-controls #submit-button').click(function() {
    $('#bulk-update').submit();
  });

  $('.line-item input').keyup(function() {
    stock_item_input(this);
  });

  $('.line-item .remove').click(function() {
    input_element = $(this).closest('.line-item').find('input')[0];
    $(input_element).val('');
    stock_item_input(input_element);
  });
});

function stock_item_input(element) {
  warning        = $(element).closest('.line-item').find('.warning');
  remove         = $(element).closest('.line-item').find('.remove');
  original_value = $(element).data('original-value');
  current_value  = $(element).val();

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

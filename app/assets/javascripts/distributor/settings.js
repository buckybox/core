$(function() {
  $('.line-item input').keyup(function() {
    stock_item_edit(this);
  });

  $('.line-item .remove').click(function() {
    input_element = $(this).closest('.line-item').find('input');
    stock_item_edit(input_element);
  });
});

function stock_item_edit(element) {
  warning        = $(element).closest('.line-item').find('.warning');
  original_value = $(element).data('original-value');
  current_value  = $(element).val();

  console.info(current_value);
  console.info(original_value);
  console.info(current_value != original_value);

  if(current_value != original_value) {
    warning.show();
  }
  else {
    warning.hide();
  }
}

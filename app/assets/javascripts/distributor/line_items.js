$(function() {
  $('.line-item .remove').click(function() {
    input = $(this).parent().find('input.input-text')[0];
    $(input).val('');
  });
});

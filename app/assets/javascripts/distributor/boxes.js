$(function() {
  update_extra_options = function(){
    if ($("#box_extra_option").val() == "No") {
      $("#extras_form").hide();
      $("#box_extras_limit").parent().hide();
      $("#box_extras_limit").val(0);
      $("#box_extras_limit").prop('min', 0);
    } else if($("#box_extra_option").val() == "Unlimited") {
      $("#extras_form").show();
      $("#box_extras_limit").parent().hide();
      $("#box_extras_limit").prop('min', -1);
      $("#box_extras_limit").val(-1);
    } else {
      $("#box_extras_limit").prop('min', 0);
      if($("#box_extras_limit").val() == -1) {
        $("#box_extras_limit").val(0);
      }
      $("#box_extras_limit").parent().show();
      $("#extras_form").show();
    }
  };
  $("#box_extra_option").change(update_extra_options);
  update_extra_options();
});

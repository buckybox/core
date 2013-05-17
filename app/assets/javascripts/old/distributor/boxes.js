$(function(){
  var update_box_exclusion_limits = function(){
    if($('#box_dislikes:checked').size() == 0){
      $(".exclusions_limit").hide();
    }else{
      $(".exclusions_limit").show('highlight');
    }
  }

  var update_box_substitutions_limits = function(){
    if($('#box_likes:checked').size() == 0){
      $(".substitutions_limit").hide();
    }else{
      $(".substitutions_limit").show('highlight');
    }
  }

  update_box_exclusion_limits();
  update_box_substitutions_limits();

  $("#box_dislikes").click(update_box_exclusion_limits);
  $("#box_likes").click(update_box_substitutions_limits);
});

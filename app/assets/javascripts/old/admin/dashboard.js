$(function(){
  $(".show-hide-details").click(function(){
    $(this).parent().parent().parent().find(".cron-log-details").toggleClass('hide');
  });
});

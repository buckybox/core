$(function() {
  var introTour = $('#intro-tour');

  if(introTour.length > 0) {
    if(introTour.data('show-tour') === true) {
      introTour.modal();
    }

    $('#show-intro-tour').click(function() {
      introTour.modal();
    });
  }
});

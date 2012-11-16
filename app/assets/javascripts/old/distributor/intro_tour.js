$(function() {
  var introTour = $('#intro-tour');
  var closeIntroTour = $('#close-intro-tour');

  if(introTour.length > 0) {
    if(introTour.data('show-tour') === true) {
      introTour.modal();
    }

    $('#show-intro-tour').click(function() {
      introTour.modal();
    });

    introTour.on('hide', function () {
      var tourType = introTour.data('tour-type');

      $.ajax({
        url: '/distributor/intro_tour/dismiss',
        type: 'POST',
        dataType: 'json',
        data: { tour_type: tourType },
      });
    });
  }
});

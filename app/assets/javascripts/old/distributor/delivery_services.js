/* Show a confirmation dialog box when checkboxes are unchecked
 * from a the inital page load state of checked.  This allows
 * a confirmation dialog box to be shown to confirm that the deletion
 * to a delivery service's weekday is confirmed.
 *
 * To use:
 * add data-conditional-confirm to the submit button and include in it
 * the text to be shown as the confirm dialog
 * add data-conditional-on as a key ('delivery_service_deleted' is already used)
 * and update the switch method below to accomodate the new key
 */

$(function() {
  var inputs = $('input[data-conditional-confirm]');
  window.conditionalConfirms = {};

  inputs.each(function(index, element) {
    var conditionalOn = $(element).attr('data-conditional-on')

    switch(conditionalOn) {
      case 'delivery_service_deleted':
        var weekdays = {};
        $("#weekdays input[type='checkbox']").each(function(index, weekday) {
          weekday = $(weekday);
          weekdays[weekday.attr('id')] = weekday.prop('checked');
        });
        window.conditionalConfirms[element] = weekdays;
        break;
    }
  });
  inputs.click(function() {
    var conditionalOn = $(this).attr('data-conditional-on')
    switch(conditionalOn) {
      case 'delivery_service_deleted':
        var deleted = false;
        var prevWeekdays = window.conditionalConfirms[this];
        $("#weekdays input[type='checkbox']").each(function(index, weekday){
          currentWeekday = $(weekday);
          var prevWeekday = prevWeekdays[currentWeekday.attr('id')]
          if(prevWeekday && !currentWeekday.prop('checked')) { //Was checked, is now not checked
            deleted = true;
            return false; //break each() loop early
          }
        });
        break;
    }
    if(deleted) {
      return $.rails.confirm($(this).attr('data-conditional-confirm'));
    } else {
      return true;
    }
  });
});

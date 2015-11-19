# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/
$ ->
  # Show or hide the extras form on create/edit boxes
  update_box_extras_collection = ->
    all_extras = $("#box_all_extras").val() == "true"

    if all_extras
      $("#box_extras_collection").hide()
    else
      $("#box_extras_collection").show()

  $("#box_all_extras").change(update_box_extras_collection)

  # Show or hide the extras checkboxes on create/edit boxes
  update_box_extras = ->
    extras = $("#box_extras_limit").val() != "0"
    if extras
      $("#box_extras").show()
    else
      $("#box_extras").hide()

  $("#box_extras_limit").change(update_box_extras)

  # Update the extra checkboxes to reflect the selections made by above drop downs, then submit form
  $("#box_submit").click ->
    extras = $("#box_extras_limit").val() != "0"
    all_extras = $("#box_all_extras").val() == "true"

    if !extras
      $("#box_extras_collection input").prop("checked", false)
    else if all_extras
      $("#box_extras_collection input").prop("checked", true)
    true

  # Make sure to run the show/hide on page load to get the correct initial state
  update_box_extras_collection()
  update_box_extras()


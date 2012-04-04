# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/
$ ->
  update_box_extras = ->
    box_id = $("#order_box_id").val()
    $.get "/distributor/accounts/#{current_account_id}/boxes/#{box_id}/extras", (data) ->
      $("#extras_form").html(data)
  $("#order_box_id").change(update_box_extras)

# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/
$ ->
  update_distributor_box_extras = ->
    box_id = $("#distributor_order_box_id").val()
    $.get "/distributor/accounts/#{current_account_id}/boxes/#{box_id}/extras", (data) ->
      $("#distributor_extras_form").html(data)
  $("#distributor_order_box_id").change(update_distributor_box_extras)

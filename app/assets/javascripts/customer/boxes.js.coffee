# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/
$ ->
  update_customer_box_extras = ->
    box_id = $("#customer_order_box_id").val()
    $.get "/customer/boxes/#{box_id}/extras", (data) ->
      $("#customer_extras_form").html(data)
      update_order_extras_collection = ->
        include_extras = $("#order_include_extras").prop("checked")
        if include_extras
          $("#order_extras").show()
        else
          $("#order_extras").hide()
      $("#order_include_extras").change(update_order_extras_collection)
      update_order_extras_collection()
  $("#customer_order_box_id").change(update_customer_box_extras)

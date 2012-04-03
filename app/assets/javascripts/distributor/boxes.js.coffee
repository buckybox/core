# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/
$ ->
  update_box_extras = ->
    # box_extras is defined on distributor/orders/_form.html.haml
    limit = box_extras[$("#order_box_id").val()]
    switch limit
      when -1
        $("#extras_selection .extra_not_allowed").hide()
        $("#extras_selection .extra_limited").hide()
        $("#extras_selection .extra_unlimited").show()
      when 0
        $("#extras_selection .extra_not_allowed").show()
        $("#extras_selection .extra_limited").hide()
        $("#extras_selection .extra_unlimited").hide()
      else
        $("#extras_selection .extra_not_allowed").hide()
        $("#extras_selection .extra_limited").show()
        $("#extras_selection .extra_unlimited").hide()
        $("#extras_limit").html(limit)
    
  $("#order_box_id").change(update_box_extras)



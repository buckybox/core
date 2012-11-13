# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

$(document).ready ->
  $(".dismiss").click ->
    
    $(this).parent().parent().css("opacity", 0.5)
    $.ajax({url: $(this).attr("href"), type: "POST"})
    $(this).replaceWith("dismissed")
    return false

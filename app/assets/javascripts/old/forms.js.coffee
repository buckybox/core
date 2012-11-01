# Place all the behaviors and hooks related to the forms here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

$(document).ready ->
  wrapper = $('<div/>').css({height:0,width:0,'overflow':'hidden'})
  fileInput = $(':file').wrap(wrapper)

  fileInput.change ->
    arr = $(this).val().split("\\")
    filename = arr[arr.length-1]||$(this).val()
    $(this).closest("div.controls").find("span.description").text(filename)

  $('.file-input').click ->
    $(this).closest("div.controls").find("input.file").click()
  .show()

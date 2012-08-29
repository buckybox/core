# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/
$ ->
  load_settings = ->
    id = $('#distributor_country_id').val()
    $.get("/admin/distributors/country_setting/#{id}", (data) ->
      $("#distributor_time_zone").val(data.time_zone)
      $("#distributor_currency").val(data.currency)
      $("#distributor_consumer_delivery_fee").val(data.fee)
    , 'json'
    )
  $('#distributor_country_id').change ->
    load_settings()
  load_settings()

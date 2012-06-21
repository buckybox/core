# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/
$ ->
  window.payments = {
    load: ->
      $(".chosen-payee-select").chosen()
      $(".auto_submit").change ->
        $('.ajax_loader_hide').hide()
        $('.ajax_loader_gif').show()
        $(this).closest('form').submit()
      $("#upload_more_transactions_link").click((event) ->
        $('#upload_more_transactions .error_notification').hide()
        $('#upload_more_transactions .error').hide()
        $("#upload_more_transactions").reveal()
        event.stopPropagation()
        false
      )
    reload: ->
      $(".chosen-payee-select").chosen()
      $(".row_description").unbind()
      $(".row_description").click ->
        $(this).next().toggle()
        $(this).closest("tr.row_description").find(".edit_row_match").toggle()
        $(this).closest("tr.row_description").find(".show_row_match").toggle()
      $("div.edit_row_match input[type=submit]").unbind()
      $("div.edit_row_match input[type=submit]").click((event) ->
        $(this).prop('disabled', 'disabled')
        $(this).closest('tr').find('form').submit()
        event.stopPropagation() # Dont trigger the .row_description click
      )

      # Don't trigger the .row_description click when clicking a
      # customer badge
      $("table.payments a.customer-badge").unbind()
      $("table.payments a.customer-badge").click((event) ->
        event.stopPropagation()
        window.load($(this).attr('href'))
      )

      # Reset ajax spinners
      $('.ajax_loader_hide').show()
      $('.ajax_loader_gif').hide()
    load_more_rows_on_bottom: ->
      last_row_id = $("tr.row_description:last").attr("data-row-id")
      $('.ajax_loader_hide').hide()
      $('.ajax_loader_gif').show()
      $.getScript("/distributor/import_transactions/#{last_row_id}/load_more_rows/bottom")
  }
  window.payments.load()
  window.payments.reload()

# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/
$ ->
  window.payments = {
    # Run once on page load
    load: ->
      # Submit file upload when file is selected
      $(".auto_submit").change ->
        $('.ajax_loader_hide').hide()
        $('.ajax_loader_gif').show()
        $(this).closest('form').submit()

      # Hide errors when lightbox is hidden
      $("#upload_more_transactions_link").click((event) ->
        $('#upload_more_transactions .error_notification').hide()
        $('#upload_more_transactions .error').hide()
        $("#upload_more_transactions").reveal()
        false
      )
    # Run once at page load and every time the page changes
    reload: ->
      # Apply chosen to the select inputs
      # Draft payments are always visible, so save rendering time by not doing the visible check (I think quiet costly)
      $("select.chosen-payee-select.draft-payment").chosen()
      # Perform visible check on those that will probably be hidden
      $("select.chosen-payee-select.not-draft-payment").each((index, value) ->
        edit_row_match = $(value).closest('.edit_row_match')
        edit_row_match_visible = edit_row_match.is(":visible")
        #hack to get around chosen.js width issue which happens when the select box is hidden when it is applied
        edit_row_match.show() unless edit_row_match_visible
        $(value).chosen()
        edit_row_match.hide() unless edit_row_match_visible
      )

      $(".row_description").unbind()
      $(".row_description").click((event) ->
        clicked = $(event.target)
        if clicked.is("td") || clicked.is("div.show_row_match") || clicked.is("form") || clicked.is("div.row")
          $(this).next().toggle()
          $(this).closest("tr.row_description").find(".edit_row_match").toggle()
          $(this).closest("tr.row_description").find(".show_row_match").toggle()
      )
      $("div.edit_row_match input[type=submit]").unbind()
      $("div.edit_row_match input[type=submit]").click((event) ->
        $(this).prop('disabled', 'disabled')
        $(this).closest('tr').find('form').submit()
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

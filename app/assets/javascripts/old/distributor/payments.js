$(function() {
  window.payments = {
    load: function() {
      $("#upload_btn").click(function(event){
        $("#import_transaction_list_csv_file").trigger('click');
        return false;
      });

      $("#import_transaction_list_csv_file").change(function() {
        $('.ajax_loader_hide').hide();
        $('#payment-tables .ajax_loader_gif').show();

        return $(this).closest('form').submit();
      });

      $("#upload_more_transactions_link").click(function(event) {
        $('#upload_error_messages').hide();
        $("#upload_more_transactions").reveal();

        return false;
      });

      return $("select.chosen-payee-select").change(function(event) {
        var background;

        background = $(event.target).closest(".chosen-background");
        background.addClass('grey');
        background.removeClass('yellow');
        background.removeClass('red');

        return background.removeClass('green');
      });
    },

    reload: function() {
      $("select.chosen-payee-select.draft-payment").select2();

      $("select.chosen-payee-select.not-draft-payment").each(function(index, value) {
        var edit_row_match, edit_row_match_visible;
        edit_row_match = $(value).closest('.edit_row_match');
        edit_row_match_visible = edit_row_match.is(":visible");

        if (!edit_row_match_visible) {
          edit_row_match.removeClass('hidden');
        }

        $(value).select2();

        if (!edit_row_match_visible) {
          return edit_row_match.addClass('hidden')
        }
      });

      $(".row_description").unbind();

      $(".row_description").click(function(event) {
        var clicked;
        clicked = $(event.target);

        if (clicked.is("td") || clicked.is("div.show_row_match") || clicked.is("form") || clicked.is("div.row") || clicked.is("span.customer-name")) {
          $(this).closest("tr").next().toggleClass('hidden');

          $(this).closest("tr.row_description").find(".edit_row_match").toggleClass('hidden');
          $(this).closest("tr.row_description").find(".show_row_match").toggleClass('hidden');
        }
      });

      $("div.edit_row_match input[type=submit]").unbind();

      $("div.edit_row_match input[type=submit]").click(function(event) {
        $(this).prop('disabled', 'disabled');

        return $(this).closest('tr').find('form').submit();
      });

      $('.ajax_loader_hide').show();

      return $('#payment-tables .ajax_loader_gif').hide();
    },

    load_more_rows_on_bottom: function() {
      var last_row_id;
      last_row_id = $("tr.row_description:last").attr("data-row-id");

      $('.ajax_loader_hide').hide();
      $('#payment-tables .ajax_loader_gif').show();

      return $.getScript("/distributor/import_transactions/" + last_row_id + "/load_more_rows/bottom");
    }
  };

  window.payments.load();
  window.payments.reload();

  $("#omni_importer_menu li").click(function(){
    var target = $(this);
    var id = target.data('id');
    var label = target.data('label');

    $("#import_transaction_list_omni_importer_id").val(id);
    $("#upload_btn").html(label);
  });
});


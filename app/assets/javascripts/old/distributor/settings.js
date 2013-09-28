$(function(){
  $("#organisation_submit").click(function(){
    if ($("#distributor_has_balance_threshold:checked").size() !== 0) {
      $("#organisation_submit").attr('disabled', 'disabled');

      $.post("/distributor/settings/spend_limit_confirmation", {
         spend_limit: $("#distributor_default_balance_threshold").val(),
         update_existing: $("#distributor_spend_limit_on_all_customers:checked").size(),
         send_halt_email: $("#distributor_send_halted_email:checked").size()
       },
       function(data) {
         if (data !== "safe" && !confirm(data)) return false;
       }
      ).complete(function() {
        $("#organisation_submit").removeAttr('disabled');
      });
    }
  });

  // Show/hide spend limit (balance_threshold) extra fields
  $("#distributor_has_balance_threshold").change(function() {
    $("#balance_threshold").toggle(
      $("#distributor_has_balance_threshold").is(":checked")
    );
  }).trigger("change");

  if ($("#products").length) {
    // Enable Bootstrap components
    $('i[data-toggle="tooltip"]').tooltip();
    $("form.collapse").collapse();

    // Photo uploader rollover
    $(".edit .photo").on({
      mouseenter: function() { $(this).find("a").show(); },
      mouseleave: function() { $(this).find("a").hide(); },
    });
    $(".edit .photo .upload").click(function() {
      $(this).closest(".edit").find("#box_box_image").trigger('click');
    });

    // Toggle extra items visibility
    $('.edit input[id="box_extras_allowed"]').change(function() {
      $(this).closest(".edit").find(".extra-items").toggle($(this).is(":checked"));
    }).trigger('change');

    // Toggle box extras visibility
    $('.edit select[id="box_all_extras"]').change(function() {
      $(this).closest(".edit").find(".box-extras").toggle($(this).val() === "false");
    }).trigger('change');

    // Turn links into dropdowns
    $(".edit .selector").each(function() {
      var link = $(this).find("a");
      var select = $(this).find("select");
      var selected = select.find("option:selected");

      link.text(selected.text());
      link.hover(function() {
        link.hide(); select.show();
      });

      select.hide();
    });

    // Turn box extras dropdown into a Select2 one
    $(".edit .box-extras select").select2({ width: '100%' });
  }

  if ($("#payments").length) {
    var update_preview = function() {
      var klass = this.id;
      if (!klass) return;

      var inputs = $('form [id="' + klass + '"]');
      var text = '';
      inputs.each(function() {
        if (text !== '') text += '-';
        text += this.value;
      });

      text = text.replace(/(\n|\r|\r\n)/g, '<br>');
      $(".payment-message ." + klass)[0].innerHTML = text;

      $("#payments .preview").toggle(
        $("#payments .preview .payment-message").text().trim() != ""
      );
    };

    var fields = $("form :input:visible");
    fields.on('keyup', update_preview);
    fields.trigger('keyup');

    fields.filter('[data-toggle="tooltip"]').tooltip({ 'trigger': 'focus' });
  }
});


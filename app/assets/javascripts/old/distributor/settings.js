$(function(){
  if ($("#organisation").length) {
    // Show/hide spend limit (balance_threshold) extra fields
    $("#distributor_has_balance_threshold").change(function() {
      $("#balance_threshold").toggle(
        $("#distributor_has_balance_threshold").is(":checked")
      );
    }).trigger("change");

    $("form").submit(function(event) {
      event.preventDefault();

      var form = this;
      var submit = $(form).find("input[type='submit']");

      submit.button('loading');

      if ($("#distributor_has_balance_threshold").is(":checked")) {
        $.post("/distributor/settings/spend_limit_confirmation", {
           spend_limit: $("#distributor_default_balance_threshold").val(),
           update_existing: $("#distributor_spend_limit_on_all_customers:checked").size(),
           send_halt_email: $("#distributor_send_halted_email:checked").size()
         },
         function(data) {
           if (data === "safe" || confirm(data)) {
             form.submit();
           } else {
             submit.button('reset');
           }
         }
        );
      } else {
        form.submit();
      }
    });
  }

  if ($("#products").length) {
    // Enable Bootstrap components
    $('[data-toggle="tooltip"]').tooltip();

    if ($("#products > .boxes").length) {
      // Toggle action bar visibility
      $("#new_box")
        .on('show', function() {
          $('a.action[data-toggle="collapse"][data-target="#new_box"]').closest('tr').hide();
        })
        .on('hide', function() {
          $('a.action[data-toggle="collapse"][data-target="#new_box"]').closest('tr').show();
        });

      // Photo uploader rollover
      $(".edit .photo").on({
        mouseenter: function() { $(this).find("a").show(); },
        mouseleave: function() { $(this).find("a").hide(); },
      });
      $(".edit .photo .upload").click(function() {
        $(this).closest(".edit").find("#box_box_image").trigger('click');
      });

      // Toggle links visibility
      $('.edit input[id="box_likes"], .edit input[id="box_dislikes"]').change(function() {
        $(this).closest(".line").find(".selector").toggle( $(this).is(":checked") );
      }).trigger('change');

      // Toggle extra items visibility
      $('.edit input[id="box_extras_allowed"]').change(function() {
        $(this).closest(".edit").find(".extra-items").toggle( $(this).is(":checked") );
      }).trigger('change');

      // Toggle box extras visibility
      $('.edit select[id="box_all_extras"]').change(function() {
        var all_extras = $(this).val() != false;
        var box_extras = $(this).closest(".edit").find(".box-extras");

        if ($(this).data("original-value") != false) {
          box_extras.find("#box_extra_ids").val(""); // clear extras
        }

        box_extras.toggle(!all_extras);
      }).trigger('change');

      // Turn links into dropdowns
      $(".edit .selector").each(function() {
        var link = $(this).find("a");
        var select = $(this).find("select");
        var selected = select.find("option:selected");

        link.text( selected.text() ).click(function() {
          link.hide();
          select.show();
        });

        select.change(function() {
          $(this).hide();
          link.text( $(this).find("option:selected").text() ).show();
        }).hide();
      });

      // Turn box extras dropdown into a Select2 one (only when a box is clicked otherwise Select2
      // freezes the page load when there are heaps of boxes and extras)
      $(".edit .collapse").on("shown", function() {
        $(this).find(".box-extras select").select2({ width: '100%' });
      });
    }

    if ($("#products > .box_items").length) {
      $("form tr:not(.edit), form a.cancel").click(function() {
        $("form table tr").each(function() {
          $(this).toggle();
        });

        $("form .form-actions").toggle();
      });

      $("#products > .box_items tr.edit input.name").keyup(function() {
        var warning = $(this).closest('tr').find('.warning');
        var remove = $(this).closest('tr').find('.remove');
        var original_value = $(this).data('original-value');
        var current_value  = $(this).val();

        warning.toggle(current_value !== original_value);
        remove.toggle(current_value.length !== 0);
      }).trigger('keyup');

      $("#products > .box_items tr.edit .remove").click(function(event) {
        event.preventDefault();

        var input = $(this).closest('tr').find('input');
        input.val('');
        input.trigger('keyup');
      });
    }

    if ($("#products > .extra_items").length) {
      // Toggle action bar visibility
      $("#new_extra")
        .on('show', function() {
          $('a.action[data-toggle="collapse"][data-target="#new_extra"]').closest('tr').hide();
        })
        .on('hide', function() {
          $('a.action[data-toggle="collapse"][data-target="#new_extra"]').closest('tr').show();
        });
    }
  }

  $("#org_banner_file_upload").click(function(event){
    $("#settings_webstore_form_org_banner_file").trigger('click');
    return false;
  });

  $("#team_photo_file_upload").click(function(event){
    $("#settings_webstore_form_team_photo_file").trigger('click');
    return false;
  });

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

    var fields = $("form :input:not([type='checkbox']):visible");
    fields.on('keyup', update_preview);
    fields.trigger('keyup');

    fields.filter('[data-toggle="tooltip"]').tooltip({ 'trigger': 'focus', 'container': 'body' });
  }


  $(".important_action").click(function(event){
    if(event.target === this){
      var input = $(this).find("input");
      input.trigger("click");
    }
  });
});


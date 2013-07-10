var BuckyBoxSignUpWizard = function() {
  this.id = "bucky_box_sign_up_wizard"
  this.host = "//staging.buckybox.com"

  this.push = function() {
    for (var i = 0; i < arguments.length; i++) {
      var fn = arguments[i][0];
      var args = arguments[i].slice(1);

      this[fn].apply(this, args);
    }
  };

  this.setHost = function(host) {
    this.host = host;
  };

  this.show = function() {
    $("<iframe />", {
      name: this.id,
      id: this.id,
      src: this.host + "/sign_up_wizard/form",
      frameborder: "0",
      style: "display: block; height: 100%; position: fixed; top: 5%; left: 50%; width: 100%; margin-left: -310px;",
      "data-id": this.id,
      "data-host": this.host
    }).load(function() {
      // iframe loaded
      var iframe = this;

      // redefine jQuery selector to select within iframe
      var $ = function(selector) {
        return jQuery(iframe).contents().find(selector);
      };

      var id = this.getAttribute("data-id");
      var host = this.getAttribute("data-host");

      var visible_step = $(".step:visible");
      var current_step = visible_step;

      // register event handlers
      $("#close").click(function() {
        alert("Sorry buddy, you shall not quit now!"); // FIXME
      });

      $("#distributor_country").change(function() {
        update_country();
      });

      var url_prefix = "my.buckybox.com/";

      // copy parameterzed text into URL field
      $("#distributor_name").change(function() {
        var slug = $(this).val().
          replace(/\s/g, '-').replace(/[^a-zA-Z0-9\-]/g, '').
          toLowerCase();

        $("#distributor_parameter_name").val(url_prefix + slug);
      });

      $("#distributor_parameter_name").on("blur", function() {
        if ($(this).val().indexOf(url_prefix) !== 0) {
          $(this).val(url_prefix + $(this).val());
        }
      });

      // toggle bank deposit details visibility
      $("#distributor_payment_bank_deposit").change(function() {
        if ($("#distributor_bank_name option").length <= 1) {
          return false;
        }

        // HTML5 validation don't happen on disabled fields
        $("#bank_deposit_details :input").prop("disabled", !this.checked);

        $("#bank_deposit_details").toggle(this.checked);
      });

      // turn those dropdowns into neat custom comboboxes
      $("#distributor_bank_name").combobox();
      $("#distributor_source").combobox();

      var update_country = function() {
        jQuery.ajax({
          type: "GET",
          url: host + "/sign_up_wizard/country",
          data: "country=" + $("#distributor_country").val(),
          success: function(response) {
            // update address fields
            $("#address_fields").html(response.address).find("div").each(function() {
              var inputs = $(this).find("input");
              inputs.css("width", (420 - 7 * (inputs.length - 1)) / inputs.length);
            });

            // hide bank deposit details
            $("#bank_deposit_details").hide();
            $("#bank_deposit_details :input").prop("disabled", true);

            // populate bank list
            $("#distributor_bank_name").html("");
            jQuery.each(response.banks, function() {
              $("#distributor_bank_name").append(jQuery("<option />").val(this).text(this));
            });

            register_validity_handlers();
          }
        });
      };

      update_country();

      var is_last_step = function() {
        return (visible_step[0] == $(".step").last()[0]);
      };

      var is_first_step = function() {
        return (visible_step[0] == $(".step").first()[0]);
      };

      // update button texts
      var update_buttons = function() {
        $("#back").toggle(!is_first_step());
        $("#next").val(is_last_step() ? "Done!" : "Next");
      };

      var update_step_counter = function() {
        var steps = $(".step");
        $("#step").html(1 + steps.index(visible_step) + "/" + steps.length);
      };

      var change_step = function(direction) {
        var step = $(".step:visible").hide();
        step = (direction == 1 ? step.next() : step.prev());

        step.show(0, function() {
          current_step = step;
        });

        visible_step = step;

        update_step_counter();
        update_buttons();
      };

      // register navigation handlers
      $("#next").click(function(e) {
        var valid = true;

        $(".step:visible input").each(function() {
          if (!this.checkValidity()) {
            valid = false;
            return false;
          }
        });

        if (valid) {
          if (is_last_step()) {
            var form = $('form');

            jQuery.ajax({
              type: "POST",
              url: host + "/sign_up_wizard/sign_up",
              data: form.serialize(),
              beforeSend: function() {
                $("#message").hide();
              },
              success: function(response) {
                jQuery("#" + id).remove();
              },
              error: function(response) {
                $("#message").html(response.responseText).show();
              }
            });
          } else {
            change_step(1);
          }
        }
        // else render HTML5 validation messages
      });

      $("#back").click(function() {
        change_step(-1);
        $("#message").hide();
      });

      // register validation handlers
      var password = $("#distributor_password");
      var password_confirmation = $("#distributor_password_confirmation");

      var checkPasswordValidity = function() {
          if (password.val() != password_confirmation.val()) {
              password_confirmation[0].setCustomValidity("Passwords must match.");
          } else {
              password_confirmation[0].setCustomValidity("");
          }
      };

      password.change(checkPasswordValidity);
      password_confirmation.change(checkPasswordValidity);

      var register_validity_handlers = function() {
        $(".step:not(:visible) input").prop("disabled", true);

        $(":input").on("invalid", function() {
          if ($(this).closest(".step")[0] != current_step[0]) {
            return false; // don't validate hidden inputs
          } else {
            $(this).addClass("invalid");
          }
        }).on("change", function() {
          $(this)[0].setCustomValidity("");

          if ($(this)[0].validity.valid) {
            $(this).removeClass("invalid");
          }
        });
      };

      register_validity_handlers();

    }).appendTo("body");

  };

};

var _old_bucky_box_sign_up_wizard = window._bucky_box_sign_up_wizard || [];
window._bucky_box_sign_up_wizard = new BuckyBoxSignUpWizard;
window._bucky_box_sign_up_wizard.push.apply(window._bucky_box_sign_up_wizard, _old_bucky_box_sign_up_wizard);


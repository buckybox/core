var BuckyBoxSignUpWizard = function() {
  this.id = "bucky_box_sign_up_wizard"
  this.host = "https://my.buckybox.com"

  var active = false;

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
    // prevent to load the wizard twice
    if (active) {
      alert("Bucky Box sign up wizard is already open.");
      return false;
    }

    active = true;

    var host = this.host,
          id = this.id,
         css = host + "/assets/sign_up_wizard.css";

    $.ajax({
      url: css,
      dataType: "text",
      error: function() {
        active = false;
        alert("Sorry, Bucky Box sign up wizard cannot be loaded.");
      },
      success: function() {
        // could be nicer but have to use that way for IE compat
        $("head").append('<link rel="stylesheet" type="text/css" href="' + css + '" />');

        $.get(host + "/sign_up_wizard/form", function(data) {
          $("<div />", { id: id, name: id })
            .addClass("ui-front") // used by jQuery UI for comboboxes
            .html(data)
            .appendTo("body");

          // jQuery selector within our div
          var sign_up_wizard = function(selector) {
            return $("#" + id + " " + selector);
          };

          // fake placeholders for IE
          sign_up_wizard('input, textarea').placeholder();

          var analytics = function(event) {
            if (typeof _gaq === 'undefined') {
              console.log("Google Analytics not available");
            } else {
              _gaq.push(event);
            }
          };

          analytics(['_trackPageview', '/sign_up_wizard/form#1']);

          var visible_step = sign_up_wizard(".step:visible");
          var current_step = visible_step;

          // register event handlers
          sign_up_wizard("#close").click(function() {
            sign_up_wizard("").remove();
            active = false;

            analytics(['_trackEvent', 'sign_up_wizard', 'close']);
          });

          sign_up_wizard("#distributor_country").change(function() {
            update_country();
          });

          var url_prefix = "my.buckybox.com/webstore/";

          // copy text slug into URL field
          sign_up_wizard("#distributor_name").change(function() {
            var slug = $(this).val().
              replace(/\s/g, '-').replace(/[^a-zA-Z0-9\-]/g, '').
              toLowerCase();

            sign_up_wizard("#distributor_parameter_name").val(url_prefix + slug);
          });

          sign_up_wizard("#distributor_parameter_name").on("keyup", function() {
            if ($(this).val().indexOf(url_prefix) !== 0) {
              $(this).val(url_prefix);
            }

            $(this).val(url_prefix + $(this).val().replace(url_prefix, '')
              .replace(/[^a-zA-Z0-9\-]/g, '')
            );
          });

          // toggle bank deposit details visibility
          sign_up_wizard("#distributor_payment_bank_deposit").change(function() {
            // HTML5 validation don't happen on disabled fields
            sign_up_wizard("#bank_deposit_details :input").prop("disabled", !this.checked);

            sign_up_wizard("#bank_deposit_details").toggle(this.checked);
          });

          // turn those dropdowns into neat custom comboboxes
          sign_up_wizard("#distributor_bank_name").combobox();
          sign_up_wizard("#distributor_source").combobox();

          var update_country = function() {
            $.ajax({
              type: "GET",
              url: host + "/sign_up_wizard/country",
              crossDomain: true,
              xhrFields: {
                withCredentials: true
              },
              data: "country=" + sign_up_wizard("#distributor_country").val(),
              success: function(response) {
                // update address fields
                sign_up_wizard("#address_fields").html(response.address).find("div").each(function() {
                  var inputs = $(this).find("input");
                  inputs.css("width", (420 - 7 * (inputs.length - 1)) / inputs.length);
                });

                // hide bank deposit details
                sign_up_wizard("#bank_deposit_details").hide();
                sign_up_wizard("#bank_deposit_details :input").prop("disabled", true);

                // populate bank list
                sign_up_wizard("#distributor_bank_name").html("");
                $.each(response.banks, function() {
                  sign_up_wizard("#distributor_bank_name").append($("<option />").val(this).text(this));
                });

                register_validity_handlers();
              }
            });
          };

          update_country();

          var is_first_step = function() {
            return (visible_step[0] == sign_up_wizard(".step").first()[0]);
          };

          var is_submit_step = function() {
            return visible_step.hasClass("submit");
          };

          var is_last_step = function() {
            return (visible_step[0] == sign_up_wizard(".step").last()[0]);
          };

          // update button texts
          var update_buttons = function() {
            sign_up_wizard("#back").toggle(!is_first_step() && !is_last_step());

            if (is_submit_step()) {
              sign_up_wizard("#next").val("Done!");
            } else if (is_last_step()) {
              sign_up_wizard("#next").val("Close");
            } else {
              sign_up_wizard("#next").val("Next");
            }
          };

          var update_step_counter = function() {
            if (is_last_step()) {
              sign_up_wizard("#step").hide();
            } else {
              var steps = sign_up_wizard(".step"),
                  current_step = 1 + steps.index(visible_step);

              sign_up_wizard("#step").html(current_step + "/" + (steps.length - 1));

              analytics(['_trackPageview', '/sign_up_wizard/form#' + current_step]);
            }
          };

          var change_step = function(direction) {
            var step = sign_up_wizard(".step:visible").hide();
            step = (direction == 1 ? step.next() : step.prev());

            step.show(0, function() {
              current_step = step;
            });

            visible_step = step;

            update_step_counter();
            update_buttons();
          };

          // register navigation handlers
          sign_up_wizard("#next").click(function() {
            if (is_last_step()) {
              sign_up_wizard("").remove();
              active = false;
              return false;
            }

            var valid = true;

            sign_up_wizard(".step:visible input").each(function() {
              try {
                if (!this.checkValidity()) {
                  valid = false;
                  return false;
                }
              } catch(e) {
                // IE fix
                valid = true;
              }
            });

            if (valid) {
              if (is_submit_step()) {
                var form = sign_up_wizard('form');

                // IE fix: http://stackoverflow.com/a/11187563
                $.support.cors = true;

                $.ajax({
                  type: "POST",
                  url: host + "/sign_up_wizard/sign_up",
                  crossDomain: true,
                  xhrFields: {
                    withCredentials: true
                  },
                  data: form.serialize(),
                  beforeSend: function() {
                    sign_up_wizard("footer input").attr("disabled", true);
                    sign_up_wizard("#next").val("...");

                    sign_up_wizard("#message").hide();
                  },
                  complete: function() {
                    sign_up_wizard("footer input").attr("disabled", false);
                  },
                  success: function(response) {
                    change_step(1);
                  },
                  error: function(response) {
                    update_buttons();
                    update_step_counter();

                    var message = response.responseText;
                    if (!message) {
                      message = "Oops! Something went wrong, please try again.";
                    }

                    sign_up_wizard("#message").html(message).show();
                  }
                });
              } else {
                change_step(1);
              }
            }
            // else render HTML5 validation messages
          });

          sign_up_wizard("#back").click(function() {
            change_step(-1);
            sign_up_wizard("#message").hide();
          });

          // register validation handlers
          var password = sign_up_wizard("#distributor_password");
          var password_confirmation = sign_up_wizard("#distributor_password_confirmation");

          var check_password_validity = function() {
            if (password.val() != password_confirmation.val()) {
                password_confirmation[0].setCustomValidity("Passwords must match.");
            } else {
                password_confirmation[0].setCustomValidity("");
            }
          };

          password.change(check_password_validity);
          password_confirmation.change(check_password_validity);

          var register_validity_handlers = function() {
            sign_up_wizard(":input").on("invalid", function() {
              if ($(this).closest(".step")[0] != current_step[0]) {
                return false; // don't validate hidden inputs
              } else {
                $(this).addClass("invalid");
              }
            }).on("change", function() {
              if ($(this)[0].validity.valid) {
                $(this).removeClass("invalid");
              }
            });
          };

          register_validity_handlers();
        });
      }
    });
  };
};

var _old_bucky_box_sign_up_wizard = window._bucky_box_sign_up_wizard || [];
window._bucky_box_sign_up_wizard = new BuckyBoxSignUpWizard;
window._bucky_box_sign_up_wizard.push.apply(window._bucky_box_sign_up_wizard, _old_bucky_box_sign_up_wizard);


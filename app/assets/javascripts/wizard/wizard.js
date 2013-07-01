// TODO s/article/.step/g
// remove functions

$(function() {
  'use strict';

  var BuckySignUp = function() {
    this.visible_step = $("article:visible");
    this.current_step = this.visible_step;

    this.is_first_step = function() {
      return (this.visible_step[0] == $(".step").first()[0]);
    }

    this.is_last_step = function() {
      return (this.visible_step[0] == $(".step").last()[0]);
    }
  }

  var bucky_sign_up = new BuckySignUp;

  // update button texts
  function updateButtons() {

    $("#back").toggle(!bucky_sign_up.is_first_step());
    $("#next").val(bucky_sign_up.is_last_step() ? "Done!" : "Next");
  }

  function updateStepCounter() {
    var steps = $("article");
    $("#step").html(1 + steps.index(bucky_sign_up.visible_step) + "/" + steps.length);
  }

  function changeStep(direction) {
    var current_step = $("article:visible").hide();
    current_step = (direction == 1 ? current_step.next() : current_step.prev());

    current_step.slideDown(400, function() {
      bucky_sign_up.current_step = current_step;
    });

    bucky_sign_up.visible_step = current_step;

    updateStepCounter();
    updateButtons();
  }

  ///

  $("#close").click(function() {
    alert("Sorry buddy, you shall not quit now!"); // FIXME
  });

  $("#wizard_country").change(function() {
    // reload form formats
  });

  // copy parameterzed text into URL field
  $("#wizard_organisation_name").slug({hide: false});

  // toggle bank deposit details visibility
  $("#wizard_bank_deposit").change(function() {
    // HTML5 validation don't happen on disabled fields
    $("#bank_deposit_details :input").prop("disabled", !this.checked);

    $("#bank_deposit_details").toggle(this.checked);
  });


  var password = $("#password");
  var password_confirmation = $("#password_confirmation");

  var checkPasswordValidity = function() {
      if (password.val() != password_confirmation.val()) {
          password_confirmation[0].setCustomValidity("Passwords must match.");
      } else {
          password_confirmation[0].setCustomValidity("");
      }
  };

  password.change(checkPasswordValidity);
  password_confirmation.change(checkPasswordValidity);

  $(":input").on("invalid", function() {
    if ($(this).closest("article")[0] != bucky_sign_up.current_step[0]) {
      return false; // don't validate hidden inputs
    } else {
      $(this).addClass("invalid");
    }
  }).on("change", function() {
    if ($(this)[0].validity.valid) {
      $(this).removeClass("invalid");
    }
  });

  $("#next").click(function() {
    var valid = true;

    $("article:visible input").each(function() {
      if (!this.checkValidity()) {
        valid = false;
        return false;
      }
    });

    if (valid || true) { // FIXME
      if (bucky_sign_up.is_last_step()) {
        // alert("Cheers!");

        // move that away when validation passing
        var form = $('form');

        $.ajax({
          type: "POST",
          url: "http://localhost:3000/wizard/sign_up",
          data: form.serialize(),
          success: function(response) {
            console.log(response);
          }
        });
        // </move>

      } else {
        changeStep(1);
      }
    }
    // else render HTML5 validation messages
  });

  $("#back").click(function() {
    changeStep(-1);
  });

});


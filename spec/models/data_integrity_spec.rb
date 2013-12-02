require "spec_helper"

describe DataIntegrity do
  specify { expect { DataIntegrity.check_and_print }.not_to raise_error }
  specify { expect { DataIntegrity.check_and_email }.not_to raise_error }
end



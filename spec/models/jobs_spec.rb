require "spec_helper"

describe Jobs do
  specify { expect { Jobs.run_hourly }.not_to raise_error }
  specify { expect { Jobs.run_daily }.not_to raise_error }
end


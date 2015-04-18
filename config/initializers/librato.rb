require "librato/rails"

module Librato
  module_function def increment_async(key)
    Librato.delay(
      priority: Figaro.env.delayed_job_priority_high,
      queue: "#{__FILE__}:#{__LINE__}",
    ).increment(key)
  end
end


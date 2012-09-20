autoload :Benchmark, 'benchmark'

RSpec::Matchers.define :take_less_than do |expected|
  chain :seconds do; end

  match do |block|
    @elapsed = Benchmark.realtime do
      block.call
    end
    @elapsed.should be <= expected
  end

  failure_message_for_should do |actual|
    "expected #{actual} to take less than #{expected} but was #{@elapsed}"
  end

  failure_message_for_should_not do |actual|
    "expected #{actual} to take more than #{expected} but was #{@elapsed}"
  end
end

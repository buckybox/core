# https://github.com/rspec/rspec-rails/issues/587
# Tried updating the rspec gem but didn't fix it (guessing its not in the current version)
module RSpec
  module Mocks
    # Methods that are added to every object.
    module Methods
      def stub_chain(*chain, &blk)
        chain, blk = format_chain(*chain, &blk)
        if chain.length > 1
          if matching_stub = __mock_proxy.__send__(:find_matching_method_stub, chain[0].to_sym)
            chain.shift
            matching_stub.invoke.stub_chain(*chain, &blk)
          else
            next_in_chain = Mock.new
            stub(chain.shift) { next_in_chain }
            next_in_chain.stub_chain(*chain, &blk)
          end
        else
          stub(chain.shift, &blk)
        end
      end
    end
  end
end

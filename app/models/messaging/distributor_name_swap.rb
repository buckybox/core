# Intercom expects #contact_name to be #name,
# swap them so it makes sense.
module Messaging
  class DistributorNameSwap
    def initialize(distributor)
      @distributor = distributor
    end

    def name
      distributor.contact_name
    end

    def business_name
      distributor.name
    end

    def method_missing(method, *args)
      return distributor.send(method, *args)
    end

  private
    
    def distributor
      @distributor
    end
  end
end

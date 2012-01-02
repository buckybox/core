module DeviseRequestMacros
  def simulate_distributor
    before(:each) do
      simulate_distributor_login
    end
  end
end


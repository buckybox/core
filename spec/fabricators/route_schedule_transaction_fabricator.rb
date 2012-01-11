Fabricator(:route_schedule_transaction) do
  route!
  schedule IceCube::Schedule.new
end

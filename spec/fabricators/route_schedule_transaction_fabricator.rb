Fabricator(:route_schedule_transaction) do
  route!
  schedule Bucky::Schedule.new
end

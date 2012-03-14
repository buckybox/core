Fabricator(:order_schedule_transaction) do
  order!
  schedule Bucky::Schedule.new
end

Fabricator(:order_schedule_transaction) do
  order!
  schedule IceCube::Schedule.new
end

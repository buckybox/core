Fabricator(:schedule_rule) do
  start {Date.today}
  recur :weekly
  mon true
  tue true
  wed true
  thu true
  fri true
  sat true
  sun true
end

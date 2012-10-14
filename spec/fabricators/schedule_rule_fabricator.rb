Fabricator(:schedule_rule_weekly, class_name: :schedule_rule) do
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

Fabricator(:schedule_rule, from: :schedule_rule_weekly) do
end


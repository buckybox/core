SELECT :select
FROM orders
INNER JOIN accounts ON accounts.id = orders.account_id
INNER JOIN customers ON customers.id = accounts.customer_id
INNER JOIN schedule_rules ON schedule_rules.scheduleable_id = orders.id AND schedule_rules.scheduleable_type = 'Order'
FULL OUTER JOIN schedule_pauses ON schedule_pauses.id = schedule_rules.schedule_pause_id
WHERE customers.distributor_id = :distributor_id
AND schedule_rules.halted = 'f'
AND customers.route_id = :route_id
AND orders.active = 't'
AND (	(
		(recur is NULL OR recur = 'single') AND schedule_rules.start = ':date'
	)
	OR 
	(
		recur = 'weekly' AND schedule_rules.start <= ':date'
		AND :dow = 't'
	)
	OR 
	(
		recur = 'fortnightly' AND schedule_rules.start <= ':date'
		AND :dow = 't'
		AND (((date(':date') - (schedule_rules.start - CAST(EXTRACT(DOW from schedule_rules.start) AS integer))) / 7) % 2) = 0
	)
	OR
	(
		recur = 'monthly' AND schedule_rules.start <= ':date'
		AND :dow = 't'
		AND (CAST(EXTRACT(DAY from date(':date')) AS integer) - 1) / 7 = schedule_rules.week
	)
)AND (
	schedule_pauses.start is NULL
	OR
	schedule_pauses.start > (date ':date')
	OR
	schedule_pauses.finish <= (date ':date')
)

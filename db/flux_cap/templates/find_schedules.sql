SELECT :select
FROM orders
INNER JOIN boxes ON boxes.id = orders.box_id
INNER JOIN schedule_rules ON schedule_rules.scheduleable_id = orders.id AND schedule_rules.scheduleable_type = 'Order'
FULL OUTER JOIN schedule_pauses ON schedule_pauses.id = schedule_rules.schedule_pause_id
WHERE boxes.distributor_id = :distributor_id
AND schedule_rules.halted = 'f'
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
	)
) AND (
	schedule_pauses.start is NULL
	OR
	schedule_pauses.start > (date ':date')
	OR
	schedule_pauses.finish <= (date ':date')
)

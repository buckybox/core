-- -h localhost -U jordan -d bucky_box_development
select sum(orders.quantity) as count
from orders
inner join boxes on boxes.id = orders.box_id
inner join schedule_rules on schedule_rules.scheduleable_id = orders.id AND schedule_rules.scheduleable_type = 'Order'
full outer join schedule_pauses on schedule_pauses.id = schedule_rules.schedule_pause_id
where boxes.distributor_id = 7
AND orders.active = 't'
AND (	(
		recur is NULL AND schedule_rules.start = '2012-11-07'
	)
	OR 
	(
		recur = 'weekly' AND schedule_rules.start <= '2012-11-07'
		AND wed = 't'
	)
	OR 
	(
		recur = 'fortnightly' AND schedule_rules.start <= '2012-11-07'
		AND wed = 't'
		AND (((date('2012-11-07') - (schedule_rules.start - CAST(EXTRACT(DOW from schedule_rules.start) AS integer))) / 7) % 2) = 0
	)
	OR
	(
		recur = 'monthly' AND schedule_rules.start <= '2012-11-07'
		AND wed = 't' AND EXTRACT(DAY from date('2012-11-07')) < 8
	)
) AND (
	schedule_pauses.start is NULL
	OR
	schedule_pauses.start > (date '2012-11-07')
	OR
	schedule_pauses.finish <= (date '2012-11-07')
)

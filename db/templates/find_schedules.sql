select count(*)
from orders
inner join accounts on orders.account_id = accounts.id
inner join customers on accounts.customer_id = customers.id
inner join schedule_rules on schedule_rules.order_id = orders.id
where customers.distributor_id = 14
AND orders.active = 't'
AND (	(
	recur is NULL AND start_datetime = (timestamp '2012-08-22 14:00:00')
	)
	OR 
	(
	recur = 'weekly' AND start_datetime <= (timestamp '2012-08-22 14:00:00')
	AND wed = 't'
	)
	OR 
	(
	recur = 'fortnightly' AND start_datetime <= (timestamp '2012-08-22 14:00:00')
	AND wed = 't'
	AND ((CAST(EXTRACT('epoch' from ((timestamp '2012-08-22 14:00:00') - (start_datetime +  CAST(CAST((EXTRACT(DOW from (timestamp '2012-08-22 14:00:00')) - EXTRACT(DOW from start_datetime)) AS integer)||' days' as interval)) + 
		CASE
		WHEN EXTRACT(DOW from start_datetime) >= EXTRACT(DOW from (timestamp '2012-08-22 14:00:00')) THEN interval '7 days'
		ELSE interval '0 days'
		END)) as integer) / (7*24*60*60)) % 2) = 0
	)
	OR
	(
	recur = 'monthly' AND start_datetime <= (timestamp '2012-08-22 14:00:00')
	AND wed = 't'
	AND EXTRACT(DAY from (timestamp '2012-08-22 14:00:00')) < 8
	)
)

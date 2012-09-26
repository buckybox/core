-- -h localhost -U jordan -d bucky_box_development

SELECT schedule_rules.*, next_occurrence('2012-09-20', schedule_rules.*) as next_occurrence FROM "schedule_rules"  WHERE "schedule_rules"."id" = 2897

--`SELECT c.id, c.number, c.first_name, c.last_name, orders.id, b.next_occurrence
--`FROM customers c
--`  JOIN accounts ON accounts.id = c.id
--`  JOIN orders ON accounts.id = orders.account_id
--`  JOIN (
--`    WITH occurrences AS (
--`    SELECT customers.id as customer_id, orders.id as order_id, next_occurrence('2012-09-21', schedule_rules.*) as occurrence
--`      FROM customers
--`      JOIN accounts ON accounts.id = customers.id
--`      LEFT OUTER JOIN orders ON accounts.id = orders.account_id
--`      LEFT OUTER JOIN schedule_rules ON orders.id = schedule_rules.order_id
--`      WHERE distributor_id = 14
--`    )
--`    SELECT n.customer_id, min(a.next_occurrence) as next_occurrence
--`    FROM occurrences n
--`    LEFT OUTER JOIN (
--`      SELECT DISTINCT(min(occurrence)) as next_occurrence, occurrences.customer_id
--`      FROM occurrences
--`      WHERE occurrence IS NOT NULL
--`      GROUP BY customer_id, occurrence
--`    ) a ON n.customer_id = a.customer_id AND n.occurrence = a.next_occurrence
--`    GROUP BY n.customer_id
--`  ) b ON c.id = b.customer_id
--`  WHERE distributor_id = 14

UPDATE customers SET next_order_id = d.order_id, next_order_occurrence_date = d.next_occurrence
FROM (
  SELECT c.id, c.number, c.first_name, c.last_name, a.order_id, a.next_occurrence
  FROM customers c
  LEFT OUTER JOIN (
      WITH occurrences AS (
        SELECT customer_id, order_id, min(occurrence) as next_occurrence
        FROM (
          SELECT customers.id as customer_id, orders.id as order_id, next_occurrence(':date', schedule_rules.*) as occurrence
            FROM customers
            JOIN accounts ON accounts.id = customers.id
            JOIN orders ON accounts.id = orders.account_id AND orders.active = 't'
            JOIN schedule_rules on schedule_rules.scheduleable_id = orders.id AND schedule_rules.scheduleable_type = 'Order'
            WHERE distributor_id = :id
          ) occurrences
        GROUP BY customer_id, order_id
      )
      SELECT a.customer_id, min(b.order_id) as order_id, a.next_occurrence
      FROM (
        SELECT a.customer_id, min(a.next_occurrence) as next_occurrence
        FROM occurrences a
        GROUP BY a.customer_id
      ) a JOIN occurrences b ON a.customer_id = b.customer_id AND a.next_occurrence = b.next_occurrence
      GROUP BY a.customer_id, a.next_occurrence
      order by customer_id
  ) a ON c.id = a.customer_id
) d
WHERE customers.distributor_id = :id
AND customers.id = d.id

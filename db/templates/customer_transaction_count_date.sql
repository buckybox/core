SELECT count(*)
FROM (
  SELECT customers.id, min(transactions.created_at) transaction_date
  FROM customers
  INNER JOIN accounts ON accounts.customer_id = customers.id
  LEFT JOIN transactions ON transactions.account_id = accounts.id
  WHERE customers.distributor_id = :distributor_id
  GROUP BY customers.id
  HAVING count(transactions.id) > 0) a
WHERE transaction_date >= ':date'

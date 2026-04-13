SELECT c.customer_id, c.first_name, c.last_name, c.email
FROM medved_marmelad.customers c
WHERE c.customer_id NOT IN (
  SELECT customer_id FROM medved_marmelad.orders o
  WHERE o.order_date BETWEEN '2024-09-01' AND '2024-11-29'
);
-- SELECT table_name FROM information_schema.tables WHERE table_schema='medved_marmelad';

-- SELECT * FROM medved_marmelad.customers;

-- SELECT * FROM medved_marmelad.products;

-- SELECT * FROM medved_marmelad.orders;

-- SELECT * FROM medved_marmelad.order_items;

WITH total_spents (customer_id, total_spent) AS (
  SELECT customer_id, SUM(total_amount) AS total_spent FROM medved_marmelad.orders o GROUP BY customer_id
)

SELECT c.customer_id, c.first_name, c.last_name, t.total_spent
FROM medved_marmelad.customers c
JOIN total_spents t ON c.customer_id = t.customer_id
ORDER BY total_spent DESC LIMIT 5;


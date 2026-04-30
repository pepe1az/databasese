ALTER TABLE orders
DROP COLUMN IF EXISTS customer_name;

ALTER TABLE orders
ADD COLUMN customer_name TEXT;

UPDATE orders o
SET customer_name = c.name
FROM customers c
WHERE c.customer_id = o.customer_id;

EXPLAIN ANALYZE
SELECT
    order_id,
    order_date,
    status,
    total_amount,
    customer_name
FROM orders
WHERE order_id = 1001;

EXPLAIN ANALYZE
SELECT
    o.order_id,
    o.order_date,
    o.status,
    o.total_amount,
    c.name AS customer_name
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
WHERE o.order_id = 1001;

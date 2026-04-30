EXPLAIN ANALYZE
SELECT *
FROM customers
WHERE email = 'client42@example.com';

EXPLAIN ANALYZE
SELECT *
FROM customers
WHERE name ILIKE '%42%';

EXPLAIN ANALYZE
SELECT
    o.order_id,
    o.order_date,
    o.status,
    c.name AS customer_name,
    c.email AS customer_email,
    a.address AS delivery_address,
    p.name AS product_name,
    oi.quantity,
    oi.price_at_order
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
JOIN addresses a ON a.address_id = o.address_id
JOIN order_items oi ON oi.order_id = o.order_id
JOIN products p ON p.product_id = oi.product_id
WHERE o.order_id = 1001;

EXPLAIN ANALYZE
SELECT
    p.name AS product_name,
    SUM(oi.quantity) AS total_qty,
    SUM(oi.quantity * oi.price_at_order) AS total_revenue
FROM order_items oi
JOIN products p ON p.product_id = oi.product_id
GROUP BY p.name
ORDER BY total_qty DESC
LIMIT 10;

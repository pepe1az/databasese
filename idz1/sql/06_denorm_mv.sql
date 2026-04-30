DROP MATERIALIZED VIEW IF EXISTS mv_monthly_sales;

CREATE MATERIALIZED VIEW mv_monthly_sales AS
SELECT
    date_trunc('month', o.order_date) AS month,
    p.name AS product_name,
    c.name AS category_name,
    SUM(oi.quantity) AS total_qty,
    SUM(oi.quantity * oi.price_at_order) AS total_revenue
FROM order_items oi
JOIN orders o ON o.order_id = oi.order_id
JOIN products p ON p.product_id = oi.product_id
JOIN categories c ON c.category_id = p.category_id
GROUP BY 1, 2, 3;

CREATE INDEX idx_mv_monthly_sales_month
ON mv_monthly_sales(month);

-- Запрос к нормализованным таблицам

EXPLAIN ANALYZE
SELECT
    date_trunc('month', o.order_date) AS month,
    p.name AS product_name,
    c.name AS category_name,
    SUM(oi.quantity) AS total_qty,
    SUM(oi.quantity * oi.price_at_order) AS total_revenue
FROM order_items oi
JOIN orders o ON o.order_id = oi.order_id
JOIN products p ON p.product_id = oi.product_id
JOIN categories c ON c.category_id = p.category_id
GROUP BY 1, 2, 3
ORDER BY month, product_name;

-- Запрос к materialized view

EXPLAIN ANALYZE
SELECT *
FROM mv_monthly_sales
ORDER BY month, product_name;

DROP TABLE IF EXISTS orders_1nf;

CREATE TABLE orders_1nf (
    order_id        INTEGER,
    order_date      DATE,
    customer_name   TEXT,
    customer_email  TEXT,
    customer_phone  TEXT,
    delivery_address TEXT,
    product_name    TEXT,
    product_price   NUMERIC,
    quantity        INTEGER,
    total_amount    NUMERIC,
    status          TEXT
);

INSERT INTO orders_1nf (
    order_id,
    order_date,
    customer_name,
    customer_email,
    customer_phone,
    delivery_address,
    product_name,
    product_price,
    quantity,
    total_amount,
    status
)
SELECT
    r.order_id,
    r.order_date,
    r.customer_name,
    r.customer_email,
    r.customer_phone,
    r.delivery_address,
    trim(p.name) AS product_name,
    trim(pr.price)::NUMERIC AS product_price,
    trim(q.qty)::INTEGER AS quantity,
    r.total_amount,
    r.status
FROM orders_raw r
CROSS JOIN LATERAL unnest(
    string_to_array(r.product_names, ','),
    string_to_array(r.product_prices, ','),
    string_to_array(r.product_quantities, ',')
) AS p(name, price, qty)
CROSS JOIN LATERAL (
    SELECT p.price
) pr
CROSS JOIN LATERAL (
    SELECT p.qty
) q;

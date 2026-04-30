DROP TABLE IF EXISTS orders_raw;

CREATE TABLE orders_raw (
    order_id           INTEGER,
    order_date         DATE,
    customer_name      TEXT,
    customer_email     TEXT,
    customer_phone     TEXT,
    delivery_address   TEXT,
    product_names      TEXT,
    product_prices     TEXT,
    product_quantities TEXT,
    total_amount       NUMERIC,
    status             TEXT
);

INSERT INTO orders_raw (
    order_id,
    order_date,
    customer_name,
    customer_email,
    customer_phone,
    delivery_address,
    product_names,
    product_prices,
    product_quantities,
    total_amount,
    status
)
SELECT
    gs AS order_id,
    DATE '2025-01-01' + ((gs % 180) * INTERVAL '1 day') AS order_date,
    'Клиент ' || ((gs % 200) + 1) AS customer_name,
    'client' || ((gs % 200) + 1) || '@example.com' AS customer_email,
    '+7999' || lpad(((gs % 200) + 1)::text, 7, '0') AS customer_phone,
    'Город ' || ((gs % 20) + 1) || ', улица ' || ((gs % 50) + 1) || ', дом ' || ((gs % 100) + 1) AS delivery_address,

    CASE gs % 5
        WHEN 0 THEN 'Ноутбук, Мышь, Коврик'
        WHEN 1 THEN 'Смартфон, Чехол'
        WHEN 2 THEN 'Монитор, Кабель HDMI'
        WHEN 3 THEN 'Клавиатура, Мышь'
        ELSE 'Наушники, USB-хаб, Кабель USB'
    END AS product_names,

    CASE gs % 5
        WHEN 0 THEN '85000, 1500, 500'
        WHEN 1 THEN '60000, 1200'
        WHEN 2 THEN '25000, 700'
        WHEN 3 THEN '3500, 1500'
        ELSE '7000, 2500, 400'
    END AS product_prices,

    CASE gs % 5
        WHEN 0 THEN '1, 1, 2'
        WHEN 1 THEN '1, 2'
        WHEN 2 THEN '1, 1'
        WHEN 3 THEN '1, 1'
        ELSE '1, 1, 3'
    END AS product_quantities,

    CASE gs % 5
        WHEN 0 THEN 85000 + 1500 + 500 * 2
        WHEN 1 THEN 60000 + 1200 * 2
        WHEN 2 THEN 25000 + 700
        WHEN 3 THEN 3500 + 1500
        ELSE 7000 + 2500 + 400 * 3
    END AS total_amount,

    CASE gs % 4
        WHEN 0 THEN 'created'
        WHEN 1 THEN 'paid'
        WHEN 2 THEN 'shipped'
        ELSE 'delivered'
    END AS status
FROM generate_series(1, 1000) AS gs;

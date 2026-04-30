-- 1. Создание заказа: транзакция + SELECT ... FOR UPDATE

BEGIN;

SELECT product_id, name, price
FROM products
WHERE name IN ('Монитор', 'Коврик')
FOR UPDATE;

INSERT INTO orders (
    order_id,
    customer_id,
    address_id,
    order_date,
    status,
    total_amount
)
VALUES (
    1001,
    1,
    1,
    CURRENT_DATE,
    'created',
    25500
)
ON CONFLICT (order_id) DO UPDATE
SET
    status = EXCLUDED.status,
    total_amount = EXCLUDED.total_amount;

DELETE FROM order_items
WHERE order_id = 1001;

INSERT INTO order_items (
    order_id,
    product_id,
    quantity,
    price_at_order
)
SELECT
    1001,
    product_id,
    1,
    price
FROM products
WHERE name IN ('Монитор', 'Коврик');

COMMIT;


-- 2. Обновление статуса заказа

UPDATE orders
SET status = 'shipped'
WHERE order_id = 1001;


-- 3. Получение заказа через JOIN по 4+ таблицам

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


-- 4. Топ-10 товаров

SELECT
    p.name AS product_name,
    SUM(oi.quantity) AS total_qty,
    SUM(oi.quantity * oi.price_at_order) AS total_revenue
FROM order_items oi
JOIN products p ON p.product_id = oi.product_id
GROUP BY p.name
ORDER BY total_qty DESC
LIMIT 10;


-- 5. Поиск клиента по email

SELECT *
FROM customers
WHERE email = 'client42@example.com';


-- 6. Поиск клиента по подстроке имени

SELECT *
FROM customers
WHERE name ILIKE '%42%';

DROP TABLE IF EXISTS order_items_2nf;
DROP TABLE IF EXISTS orders_2nf;
DROP TABLE IF EXISTS products_2nf;
DROP TABLE IF EXISTS customers_2nf;

CREATE TABLE customers_2nf (
    customer_id SERIAL PRIMARY KEY,
    name        TEXT NOT NULL,
    email       TEXT NOT NULL UNIQUE,
    phone       TEXT
);

CREATE TABLE products_2nf (
    product_id SERIAL PRIMARY KEY,
    name       TEXT NOT NULL UNIQUE,
    price      NUMERIC NOT NULL
);

CREATE TABLE orders_2nf (
    order_id         INTEGER PRIMARY KEY,
    customer_id      INTEGER NOT NULL REFERENCES customers_2nf(customer_id),
    order_date       DATE NOT NULL,
    delivery_address TEXT NOT NULL,
    status           TEXT NOT NULL,
    total_amount     NUMERIC NOT NULL
);

CREATE TABLE order_items_2nf (
    order_id       INTEGER NOT NULL REFERENCES orders_2nf(order_id),
    product_id     INTEGER NOT NULL REFERENCES products_2nf(product_id),
    quantity       INTEGER NOT NULL,
    price_at_order NUMERIC NOT NULL,
    PRIMARY KEY (order_id, product_id)
);

INSERT INTO customers_2nf (name, email, phone)
SELECT DISTINCT
    customer_name,
    customer_email,
    customer_phone
FROM orders_1nf;

INSERT INTO products_2nf (name, price)
SELECT DISTINCT
    product_name,
    product_price
FROM orders_1nf;

INSERT INTO orders_2nf (
    order_id,
    customer_id,
    order_date,
    delivery_address,
    status,
    total_amount
)
SELECT DISTINCT
    o.order_id,
    c.customer_id,
    o.order_date,
    o.delivery_address,
    o.status,
    o.total_amount
FROM orders_1nf o
JOIN customers_2nf c
    ON c.email = o.customer_email;

INSERT INTO order_items_2nf (
    order_id,
    product_id,
    quantity,
    price_at_order
)
SELECT
    o.order_id,
    p.product_id,
    o.quantity,
    o.product_price
FROM orders_1nf o
JOIN products_2nf p
    ON p.name = o.product_name;

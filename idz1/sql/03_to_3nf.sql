DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS addresses;
DROP TABLE IF EXISTS customers;

CREATE TABLE customers (
    customer_id INTEGER PRIMARY KEY,
    name        TEXT NOT NULL,
    email       TEXT NOT NULL UNIQUE,
    phone       TEXT
);

CREATE TABLE addresses (
    address_id  SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES customers(customer_id),
    address     TEXT NOT NULL,
    UNIQUE (customer_id, address)
);

CREATE TABLE categories (
    category_id SERIAL PRIMARY KEY,
    name        TEXT NOT NULL UNIQUE
);

CREATE TABLE products (
    product_id  INTEGER PRIMARY KEY,
    name        TEXT NOT NULL UNIQUE,
    category_id INTEGER NOT NULL REFERENCES categories(category_id),
    price       NUMERIC NOT NULL
);

CREATE TABLE orders (
    order_id     INTEGER PRIMARY KEY,
    customer_id  INTEGER NOT NULL REFERENCES customers(customer_id),
    address_id   INTEGER NOT NULL REFERENCES addresses(address_id),
    order_date   DATE NOT NULL,
    status       TEXT NOT NULL,
    total_amount NUMERIC NOT NULL
);

CREATE TABLE order_items (
    order_id       INTEGER NOT NULL REFERENCES orders(order_id),
    product_id     INTEGER NOT NULL REFERENCES products(product_id),
    quantity       INTEGER NOT NULL,
    price_at_order NUMERIC NOT NULL,
    PRIMARY KEY (order_id, product_id)
);

INSERT INTO customers (customer_id, name, email, phone)
SELECT customer_id, name, email, phone
FROM customers_2nf;

INSERT INTO addresses (customer_id, address)
SELECT DISTINCT customer_id, delivery_address
FROM orders_2nf;

INSERT INTO categories (name)
VALUES
    ('Электроника'),
    ('Аксессуары'),
    ('Периферия'),
    ('Кабели');

INSERT INTO products (product_id, name, category_id, price)
SELECT
    p.product_id,
    p.name,
    c.category_id,
    p.price
FROM products_2nf p
JOIN categories c
    ON c.name = CASE
        WHEN p.name IN ('Ноутбук', 'Смартфон', 'Монитор', 'Наушники') THEN 'Электроника'
        WHEN p.name IN ('Мышь', 'Клавиатура', 'Коврик') THEN 'Периферия'
        WHEN p.name IN ('Кабель HDMI', 'Кабель USB') THEN 'Кабели'
        ELSE 'Аксессуары'
    END;

INSERT INTO orders (
    order_id,
    customer_id,
    address_id,
    order_date,
    status,
    total_amount
)
SELECT
    o.order_id,
    o.customer_id,
    a.address_id,
    o.order_date,
    o.status,
    o.total_amount
FROM orders_2nf o
JOIN addresses a
    ON a.customer_id = o.customer_id
   AND a.address = o.delivery_address;

INSERT INTO order_items (
    order_id,
    product_id,
    quantity,
    price_at_order
)
SELECT
    order_id,
    product_id,
    quantity,
    price_at_order
FROM order_items_2nf;

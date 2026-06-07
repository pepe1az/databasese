-- Для демонстрации берём документы с фиксированными id, которые создаёт генератор.
-- id=1: wireless bluetooth headphones
-- id=2: noise cancelling headphones
-- id=3: portable speaker near phrase

SELECT id, title, price, rating FROM products WHERE id = 1;

UPDATE products SET price = 9999.99, rating = 4.9 WHERE id = 1;
SELECT id, title, price, rating FROM products WHERE id = 1;

SELECT id, title FROM products WHERE id = 2;
DELETE FROM products WHERE id = 2;
SELECT id, title FROM products WHERE id = 2;
SELECT id, title FROM products WHERE MATCH('"noise cancelling"') AND id = 2;

REPLACE INTO products (
    id, title, description, category, brand, price, rating, reviews_count, in_stock, tags, created_at
) VALUES (
    2,
    'Replaced Noise Cancelling Headphones',
    'Replaced document for UPDATE DELETE REPLACE demonstration',
    'audio',
    'DemoBrand',
    12999.00,
    4.8,
    777,
    1,
    '{"color":"black","wireless":true,"demo":"replace"}',
    1710000000
);

SELECT id, title, price, rating, tags FROM products WHERE id = 2;

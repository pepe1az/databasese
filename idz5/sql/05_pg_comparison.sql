DROP TABLE IF EXISTS pg_products;

CREATE TABLE pg_products (
    id            bigint PRIMARY KEY,
    title         text,
    description   text,
    category      text,
    brand         text,
    price         numeric,
    rating        numeric,
    reviews_count integer,
    in_stock      boolean,
    tags          jsonb,
    created_at    timestamp
);

-- Данные загружаются скриптом scripts/load_postgres.py из data/products_pg.csv.

ALTER TABLE pg_products
ADD COLUMN IF NOT EXISTS tsv tsvector
GENERATED ALWAYS AS (to_tsvector('english', coalesce(title, '') || ' ' || coalesce(description, ''))) STORED;

CREATE INDEX IF NOT EXISTS idx_pg_products_tsv ON pg_products USING GIN(tsv);

EXPLAIN ANALYZE
SELECT title, ts_rank(tsv, q) AS rank
FROM pg_products, to_tsquery('english', 'wireless & bluetooth & headphones') q
WHERE tsv @@ q
ORDER BY rank DESC
LIMIT 10;

SELECT title, ts_rank(tsv, q) AS rank
FROM pg_products, to_tsquery('english', 'wireless & bluetooth & headphones') q
WHERE tsv @@ q
ORDER BY rank DESC
LIMIT 10;

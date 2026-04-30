-- До pg_trgm: поиск по подстроке работает через Seq Scan

EXPLAIN ANALYZE
SELECT *
FROM customers
WHERE name ILIKE '%42%';


-- Подключаем расширение pg_trgm

CREATE EXTENSION IF NOT EXISTS pg_trgm;


-- Создаём GIN-индекс для поиска по подстроке

CREATE INDEX IF NOT EXISTS idx_customers_name_trgm
ON customers
USING gin (name gin_trgm_ops);


-- После pg_trgm

EXPLAIN ANALYZE
SELECT *
FROM customers
WHERE name ILIKE '%42%';


-- Принудительная демонстрация использования индекса на маленькой таблице

SET enable_seqscan = off;

EXPLAIN ANALYZE
SELECT *
FROM customers
WHERE name ILIKE '%42%';

RESET enable_seqscan;

CREATE TABLE IF NOT EXISTS idz2.monthly_sales
(
    month        Date,
    category     LowCardinality(String),
    region       LowCardinality(String),
    revenue      Decimal(18,2),
    quantity     UInt64,
    orders_count UInt64
)
ENGINE = SummingMergeTree()
PARTITION BY toYYYYMM(month)
ORDER BY (month, category, region);

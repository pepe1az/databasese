CREATE DATABASE IF NOT EXISTS default ON CLUSTER clickhouse_cluster;

CREATE TABLE IF NOT EXISTS events ON CLUSTER clickhouse_cluster
(
    event_time DateTime,
    event_type LowCardinality(String),
    user_id UInt64,
    payload String
)
ENGINE = ReplicatedMergeTree(
    '/clickhouse/tables/{shard}/events',
    '{replica}'
)
ORDER BY (event_type, event_time)
PARTITION BY toYYYYMM(event_time);

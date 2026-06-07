-- Запускается после docker compose -f docker-compose.yml -f docker-compose.reshard.yml up -d
-- и после пересоздания/обновления конфигурации с cluster_3x2.

CREATE TABLE IF NOT EXISTS events_local_3x2 ON CLUSTER 'cluster_3x2'
(
    event_date  Date,
    event_time  DateTime,
    user_id     UInt64,
    session_id  String,
    event_type  LowCardinality(String),
    page_url    String,
    duration_ms UInt32
)
ENGINE = ReplicatedMergeTree(
    '/clickhouse/tables/{shard}/events_local_3x2',
    '{replica}'
)
PARTITION BY toYYYYMM(event_date)
ORDER BY (user_id, event_time);

CREATE TABLE IF NOT EXISTS events_distributed_3x2 ON CLUSTER 'cluster_3x2'
AS events_local_3x2
ENGINE = Distributed(
    'cluster_3x2',
    default,
    events_local_3x2,
    xxHash64(user_id)
);

INSERT INTO events_distributed_3x2
SELECT
    today() - number % 30 AS event_date,
    now() - number % 100000 AS event_time,
    number % 750000 AS user_id,
    concat('session_new_', toString(number % 150000)) AS session_id,
    ['view', 'click', 'scroll', 'purchase', 'login'][number % 5 + 1] AS event_type,
    concat('/new-page/', toString(number % 1500)) AS page_url,
    toUInt32(number % 30000) AS duration_ms
FROM numbers(600000);

SELECT
    hostName() AS host,
    count() AS rows,
    uniqExact(user_id) AS users
FROM cluster('cluster_3x2', default, events_local_3x2)
GROUP BY host
ORDER BY host;

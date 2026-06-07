INSERT INTO events_distributed
SELECT
    today() - number % 30 AS event_date,
    now() - number % 100000 AS event_time,
    number % 500000 AS user_id,
    concat('session_', toString(number % 100000)) AS session_id,
    ['view', 'click', 'scroll', 'purchase', 'login'][number % 5 + 1] AS event_type,
    concat('/page/', toString(number % 1000)) AS page_url,
    toUInt32(number % 30000) AS duration_ms
FROM numbers(2000000);

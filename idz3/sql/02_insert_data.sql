INSERT INTO events
SELECT
    now() - number % 100000 AS event_time,
    ['click', 'view', 'purchase', 'login'][number % 4 + 1] AS event_type,
    number AS user_id,
    concat('payload_', toString(number)) AS payload
FROM numbers(100000);

INSERT INTO events
SELECT
    now() AS event_time,
    'failover_a' AS event_type,
    number + 100000 AS user_id,
    concat('after_replica3_stop_', toString(number)) AS payload
FROM numbers(10000);

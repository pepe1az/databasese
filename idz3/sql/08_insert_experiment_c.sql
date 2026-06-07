INSERT INTO events
SELECT
    now() AS event_time,
    'conflict_test' AS event_type,
    number + 300000 AS user_id,
    concat('conflict_test_', toString(number)) AS payload
FROM numbers(10000);

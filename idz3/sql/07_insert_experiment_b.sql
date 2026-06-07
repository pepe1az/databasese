INSERT INTO events
SELECT
    now() AS event_time,
    'keeper_one_down' AS event_type,
    number + 200000 AS user_id,
    concat('keeper_test_', toString(number)) AS payload
FROM numbers(10000);

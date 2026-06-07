SELECT
    count() AS rows_count,
    min(event_time) AS min_event_time,
    max(event_time) AS max_event_time,
    uniqExact(user_id) AS unique_users
FROM events;

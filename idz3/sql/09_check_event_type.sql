SELECT
    event_type,
    count() AS rows_count,
    min(user_id) AS min_user_id,
    max(user_id) AS max_user_id
FROM events
GROUP BY event_type
ORDER BY event_type;

-- 1. Информация о кластере
SELECT *
FROM system.clusters
WHERE cluster = 'cluster_2x2'
FORMAT PrettyCompact;

-- 2. Глобальный COUNT через Distributed
SELECT count() AS distributed_rows
FROM events_distributed;

-- 3. Локальные строки на текущем узле
SELECT
    hostName() AS host,
    count() AS rows
FROM events_local;

-- 4. Распределение по шардам через cluster-функцию
SELECT
    hostName() AS host,
    count() AS rows,
    uniqExact(user_id) AS users
FROM cluster('cluster_2x2', default, events_local)
GROUP BY host
ORDER BY host;

-- 5. Проверка, что конкретный user_id находится на одном шарде и его репликах
SELECT
    hostName() AS host,
    count() AS rows
FROM cluster('cluster_2x2', default, events_local)
WHERE user_id = 12345
GROUP BY host
ORDER BY host;

-- 6. GROUP BY по ключу шардирования
SELECT
    user_id,
    count() AS events_count
FROM events_distributed
GROUP BY user_id
ORDER BY events_count DESC
LIMIT 10;

-- 7. GROUP BY не по ключу шардирования
SELECT
    page_url,
    count() AS visits
FROM events_distributed
GROUP BY page_url
ORDER BY visits DESC
LIMIT 10;

-- 8. JOIN со справочником пользователей
SELECT
    d.segment,
    count() AS events_count
FROM events_distributed AS e
INNER JOIN user_dict_distributed AS d
ON e.user_id = d.user_id
GROUP BY d.segment
ORDER BY events_count DESC;

-- 9. Пример GLOBAL IN для небольшого справочника/подзапроса
SELECT
    count() AS premium_events
FROM events_distributed
WHERE user_id GLOBAL IN
(
    SELECT user_id
    FROM user_dict_distributed
    WHERE segment = 'premium'
);

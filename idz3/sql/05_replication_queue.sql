SELECT *
FROM system.replication_queue
WHERE table = 'events'
FORMAT Vertical;

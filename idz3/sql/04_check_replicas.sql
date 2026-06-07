SELECT
    database,
    table,
    replica_name,
    is_leader,
    total_replicas,
    active_replicas,
    queue_size,
    inserts_in_queue,
    merges_in_queue,
    log_pointer,
    last_queue_update
FROM system.replicas
WHERE table = 'events'
FORMAT Vertical;

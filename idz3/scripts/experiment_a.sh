#!/usr/bin/env bash
set -euo pipefail

mkdir -p checks

{
  echo "===== Experiment A: stop replica 3 ====="
  docker compose stop clickhouse3

  echo
  echo "===== Insert new data into replica 1 ====="
  docker compose exec -T clickhouse1 clickhouse-client --queries-file /dev/stdin < sql/06_insert_experiment_a.sql

  echo
  echo "===== Check replica 2 received data ====="
  docker compose exec -T clickhouse2 clickhouse-client --query "SELECT event_type, count() FROM events WHERE event_type = 'failover_a' GROUP BY event_type;"

  echo
  echo "===== Start replica 3 ====="
  docker compose start clickhouse3
  sleep 10

  echo
  echo "===== Replica 3 status after recovery ====="
  docker compose exec -T clickhouse3 clickhouse-client --queries-file /dev/stdin < sql/04_check_replicas.sql

  echo
  echo "===== Replication queue on replica 3 ====="
  docker compose exec -T clickhouse3 clickhouse-client --queries-file /dev/stdin < sql/05_replication_queue.sql
} | tee checks/experiment_a.txt

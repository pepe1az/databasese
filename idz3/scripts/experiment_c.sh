#!/usr/bin/env bash
set -euo pipefail

mkdir -p checks

{
  echo "===== Experiment C: stop replica 2 ====="
  docker compose stop clickhouse2

  echo
  echo "===== Insert data into replica 1 ====="
  docker compose exec -T clickhouse1 clickhouse-client --queries-file /dev/stdin < sql/08_insert_experiment_c.sql

  echo
  echo "===== Start replica 2 ====="
  docker compose start clickhouse2
  sleep 10

  echo
  echo "===== Check conflict_test rows on all replicas ====="
  echo "--- clickhouse1 ---"
  docker compose exec -T clickhouse1 clickhouse-client --query "SELECT count() FROM events WHERE event_type = 'conflict_test';"
  echo "--- clickhouse2 ---"
  docker compose exec -T clickhouse2 clickhouse-client --query "SELECT count() FROM events WHERE event_type = 'conflict_test';"
  echo "--- clickhouse3 ---"
  docker compose exec -T clickhouse3 clickhouse-client --query "SELECT count() FROM events WHERE event_type = 'conflict_test';"

  echo
  echo "===== Replica 2 status ====="
  docker compose exec -T clickhouse2 clickhouse-client --queries-file /dev/stdin < sql/04_check_replicas.sql
} | tee checks/experiment_c.txt

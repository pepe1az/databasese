#!/usr/bin/env bash
set -euo pipefail

mkdir -p checks

run_ch() {
  local node="$1"
  shift
  docker compose exec -T "$node" clickhouse-client "$@"
}

{
  echo "===== keeper1 ruok ====="
  docker compose exec -T keeper1 bash -lc "echo ruok | nc 127.0.0.1 9181" || true
  echo
  echo "===== keeper1 mntr ====="
  docker compose exec -T keeper1 bash -lc "echo mntr | nc 127.0.0.1 9181" || true
  echo

  echo "===== keeper2 ruok ====="
  docker compose exec -T keeper2 bash -lc "echo ruok | nc 127.0.0.1 9181" || true
  echo
  echo "===== keeper2 mntr ====="
  docker compose exec -T keeper2 bash -lc "echo mntr | nc 127.0.0.1 9181" || true
  echo

  echo "===== keeper3 ruok ====="
  docker compose exec -T keeper3 bash -lc "echo ruok | nc 127.0.0.1 9181" || true
  echo
  echo "===== keeper3 mntr ====="
  docker compose exec -T keeper3 bash -lc "echo mntr | nc 127.0.0.1 9181" || true
} > checks/keeper_health.txt

run_ch clickhouse1 --queries-file /dev/stdin < sql/04_check_replicas.sql > checks/replicas_status_node1.txt
run_ch clickhouse2 --queries-file /dev/stdin < sql/04_check_replicas.sql > checks/replicas_status_node2.txt
run_ch clickhouse3 --queries-file /dev/stdin < sql/04_check_replicas.sql > checks/replicas_status_node3.txt

{
  echo "===== clickhouse1 counts ====="
  run_ch clickhouse1 --queries-file /dev/stdin < sql/03_check_counts.sql
  echo
  echo "===== clickhouse2 counts ====="
  run_ch clickhouse2 --queries-file /dev/stdin < sql/03_check_counts.sql
  echo
  echo "===== clickhouse3 counts ====="
  run_ch clickhouse3 --queries-file /dev/stdin < sql/03_check_counts.sql
} > checks/replication_counts.txt

echo "Checks saved to checks/"

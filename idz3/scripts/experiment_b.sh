#!/usr/bin/env bash
set -euo pipefail

mkdir -p checks

{
  echo "===== Experiment B: stop keeper3 ====="
  docker compose stop keeper3
  sleep 5

  echo
  echo "===== Check keeper quorum: keeper1 ====="
  docker compose exec -T keeper1 bash -lc "echo ruok | nc 127.0.0.1 9181" || true
  docker compose exec -T keeper1 bash -lc "echo mntr | nc 127.0.0.1 9181" || true

  echo
  echo "===== Check keeper quorum: keeper2 ====="
  docker compose exec -T keeper2 bash -lc "echo ruok | nc 127.0.0.1 9181" || true
  docker compose exec -T keeper2 bash -lc "echo mntr | nc 127.0.0.1 9181" || true

  echo
  echo "===== Insert data with 2 of 3 Keeper nodes alive ====="
  docker compose exec -T clickhouse1 clickhouse-client --queries-file /dev/stdin < sql/07_insert_experiment_b.sql

  echo
  echo "===== Stop keeper2: quorum is lost ====="
  docker compose stop keeper2
  sleep 5

  echo
  echo "===== Try insert without Keeper quorum: expected error ====="
  set +e
  docker compose exec -T clickhouse1 clickhouse-client --query "INSERT INTO events SELECT now(), 'keeper_quorum_lost', number + 400000, concat('lost_quorum_', toString(number)) FROM numbers(10);"
  echo "exit_code=$?"
  set -e

  echo
  echo "===== SELECT still works locally ====="
  docker compose exec -T clickhouse1 clickhouse-client --query "SELECT count() FROM events;"

  echo
  echo "===== Restore keeper2 and keeper3 ====="
  docker compose start keeper2 keeper3
} | tee checks/experiment_b.txt

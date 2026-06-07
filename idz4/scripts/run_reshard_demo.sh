#!/usr/bin/env bash
set -euo pipefail

mkdir -p checks

echo "Starting third shard demo..."
docker compose -f docker-compose.yml -f docker-compose.reshard.yml up -d
sleep 20

{
  echo "# cluster_3x2 info"
  docker exec -i ch-s1-r1 clickhouse-client --query "SELECT cluster, shard_num, replica_num, host_name, port FROM system.clusters WHERE cluster = 'cluster_3x2' ORDER BY shard_num, replica_num FORMAT PrettyCompact"
  echo
  echo "# Creating 3x2 tables and inserting new data"
  docker exec -i ch-s1-r1 clickhouse-client --multiquery < sql/06_reshard.sql
  echo
  echo "# Explanation"
  echo "Old data from events_local/events_distributed remains on the original two shards."
  echo "The new table events_distributed_3x2 routes new inserts to three shards."
  echo "Automatic rebalance of old data is not performed by ClickHouse Distributed engine."
} > checks/reshard_demo.txt

echo "Reshard demo saved to checks/reshard_demo.txt"

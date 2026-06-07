#!/usr/bin/env bash
set -euo pipefail

mkdir -p checks

CH="docker exec -i ch-s1-r1 clickhouse-client --multiquery"
QUERY="docker exec -i ch-s1-r1 clickhouse-client"

{
  echo "# system.clusters for cluster_2x2"
  docker exec -i ch-s1-r1 clickhouse-client --query "SELECT cluster, shard_num, replica_num, host_name, host_address, port FROM system.clusters WHERE cluster = 'cluster_2x2' ORDER BY shard_num, replica_num FORMAT PrettyCompact"
} > checks/cluster_info.txt

{
  echo "# Data distribution across local tables"
  docker exec -i ch-s1-r1 clickhouse-client --query "SELECT hostName() AS host, count() AS rows, uniqExact(user_id) AS users FROM cluster('cluster_2x2', default, events_local) GROUP BY host ORDER BY host FORMAT PrettyCompact"
  echo
  echo "# User 12345 placement"
  docker exec -i ch-s1-r1 clickhouse-client --query "SELECT hostName() AS host, count() AS rows FROM cluster('cluster_2x2', default, events_local) WHERE user_id = 12345 GROUP BY host ORDER BY host FORMAT PrettyCompact"
} > checks/data_distribution.txt

{
  echo "# Distributed query checks"
  docker exec -i ch-s1-r1 clickhouse-client --multiquery < sql/05_queries.sql
} > checks/distributed_queries.txt

echo "Checks saved to checks/*.txt"

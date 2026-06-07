.PHONY: up down clean create insert checks experiment-a experiment-b experiment-c status

up:
	docker compose up -d

down:
	docker compose down

clean:
	docker compose down -v

create:
	docker compose exec -T clickhouse1 clickhouse-client --queries-file /dev/stdin < sql/01_create_table.sql

insert:
	docker compose exec -T clickhouse1 clickhouse-client --queries-file /dev/stdin < sql/02_insert_data.sql

checks:
	./scripts/run_checks.sh

experiment-a:
	./scripts/experiment_a.sh

experiment-b:
	./scripts/experiment_b.sh

experiment-c:
	./scripts/experiment_c.sh

status:
	docker compose ps

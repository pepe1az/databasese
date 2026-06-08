# Отчёт по выполнению ИДЗ-3

## Репликация в ClickHouse

## 1. Цель работы

Целью лабораторной работы являлось развёртывание ClickHouse-кластера с репликацией, настройка кворума ClickHouse Keeper, создание реплицированной таблицы на движке `ReplicatedMergeTree`, а также проверка отказоустойчивости и консистентности данных между репликами.

В ходе работы необходимо было:

* развернуть кластер из трёх узлов ClickHouse;
* развернуть кворум из трёх узлов ClickHouse Keeper;
* настроить один шард и три реплики;
* создать реплицированную таблицу `events`;
* проверить синхронизацию данных между репликами;
* провести эксперименты с отказом реплики и Keeper-узлов;
* проанализировать состояние репликации через системные таблицы ClickHouse.


## 2. Используемая топология

Для выполнения работы был развёрнут кластер в Docker Compose.

Топология кластера:

| Компонент     | Назначение                    |
| ------------- | ----------------------------- |
| `clickhouse1` | первая реплика ClickHouse     |
| `clickhouse2` | вторая реплика ClickHouse     |
| `clickhouse3` | третья реплика ClickHouse     |
| `keeper1`     | первый узел ClickHouse Keeper |
| `keeper2`     | второй узел ClickHouse Keeper |
| `keeper3`     | третий узел ClickHouse Keeper |

В рамках лабораторной работы использовалась схема:

* 1 шард;
* 3 реплики;
* 3 узла ClickHouse Keeper.

Такой вариант был выбран для проверки полноценной репликации и отказоустойчивости. Три Keeper-узла позволяют сохранить работоспособность кворума при отказе одного узла, так как оставшиеся два узла всё ещё могут образовывать большинство.


## 3. Настройка ClickHouse Keeper

Для координации репликации был настроен ClickHouse Keeper. Каждый узел Keeper получил собственный `server_id`, а также общий список участников кворума.

Проверка доступности Keeper выполнялась командами:

```bash
echo ruok | nc keeper1 9181
echo mntr | nc keeper1 9181
```

Команда `ruok` использовалась для простой проверки доступности узла. При корректной работе Keeper возвращал ответ:

```text
imok
```

Команда `mntr` использовалась для получения расширенной информации о состоянии узла Keeper, включая роль узла, количество подключений, задержки и состояние кворума.

Проверка была выполнена для всех трёх узлов Keeper:

```bash
echo mntr | nc keeper1 9181
echo mntr | nc keeper2 9181
echo mntr | nc keeper3 9181
```

Результаты были сохранены в файл:

```text
checks/keeper_health.txt
```

По результатам проверки было подтверждено, что Keeper-кворум работает корректно, один из узлов выполняет роль leader, остальные находятся в состоянии follower.


## 4. Настройка ClickHouse-кластера

В конфигурации ClickHouse был настроен кластер в секции `remote_servers`.

Кластер содержит один шард и три реплики:

```xml
<remote_servers>
    <clickhouse_cluster>
        <shard>
            <replica>
                <host>clickhouse1</host>
                <port>9000</port>
            </replica>
            <replica>
                <host>clickhouse2</host>
                <port>9000</port>
            </replica>
            <replica>
                <host>clickhouse3</host>
                <port>9000</port>
            </replica>
        </shard>
    </clickhouse_cluster>
</remote_servers>
```

Также для каждого узла были настроены макросы:

```xml
<macros>
    <shard>01</shard>
    <replica>replica1</replica>
</macros>
```

Для второго и третьего узла значение `replica` было изменено соответственно на:

```text
replica2
replica3
```

Макросы необходимы для того, чтобы ClickHouse мог автоматически подставлять имя шарда и имя реплики при создании таблицы на движке `ReplicatedMergeTree`.


## 5. Создание реплицированной таблицы

После запуска кластера была создана таблица `events` на всех узлах ClickHouse с помощью конструкции `ON CLUSTER`.

SQL-запрос:

```sql
CREATE TABLE events ON CLUSTER clickhouse_cluster
(
    event_time DateTime,
    event_type LowCardinality(String),
    user_id UInt64,
    payload String
)
ENGINE = ReplicatedMergeTree(
    '/clickhouse/tables/{shard}/events',
    '{replica}'
)
ORDER BY (event_type, event_time)
PARTITION BY toYYYYMM(event_time);
```

В качестве движка был использован `ReplicatedMergeTree`.

Путь:

```text
/clickhouse/tables/{shard}/events
```

используется как общий путь таблицы в Keeper.

Параметр:

```text
{replica}
```

задаёт уникальное имя реплики для каждого узла.

После создания таблицы была выполнена проверка её наличия на всех трёх репликах:

```sql
SHOW TABLES;
```

Также можно было проверить таблицу через системную таблицу:

```sql
SELECT database, name, engine
FROM system.tables
WHERE name = 'events';
```

Таблица `events` была успешно создана на всех трёх узлах.


## 6. Проверка репликации данных

Для проверки репликации в первую реплику было вставлено более 100 000 строк.

Пример вставки тестовых данных:

```sql
INSERT INTO events
SELECT
    now() - number % 100000 AS event_time,
    ['click', 'view', 'purchase', 'login'][number % 4 + 1] AS event_type,
    number AS user_id,
    concat('payload_', toString(number)) AS payload
FROM numbers(100000);
```

После вставки данные были прочитаны со второй и третьей реплики.

Проверка количества строк:

```sql
SELECT count() FROM events;
```

Результат на всех трёх репликах:

```text
100000
```

Для дополнительной проверки совпадения данных использовался запрос:

```sql
SELECT
    count() AS rows_count,
    min(event_time),
    max(event_time),
    uniqExact(user_id) AS unique_users
FROM events;
```

Результаты на всех репликах совпали, что подтверждает корректную работу репликации.


## 7. Проверка состояния system.replicas

Для анализа состояния репликации использовалась системная таблица `system.replicas`.

Запрос:

```sql
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
```

Проверка была выполнена на всех трёх узлах.

Результаты были сохранены в файлы:

```text
checks/replicas_status_node1.txt
checks/replicas_status_node2.txt
checks/replicas_status_node3.txt
```

По результатам проверки было установлено:

* таблица `events` видит все три реплики;
* значение `total_replicas` равно `3`;
* значение `active_replicas` равно `3`;
* очередь репликации отсутствует или быстро обрабатывается;
* `queue_size` после синхронизации равен `0`.

Это означает, что репликация работает корректно, а данные между узлами согласованы.


## 8. Эксперимент A — потеря одной реплики

В первом эксперименте была проверена работа кластера при остановке одной реплики.

Была остановлена третья реплика:

```bash
docker compose stop clickhouse3
```

После этого в первую реплику были вставлены новые данные:

```sql
INSERT INTO events
SELECT
    now() AS event_time,
    'failover_a' AS event_type,
    number + 100000 AS user_id,
    concat('after_replica3_stop_', toString(number)) AS payload
FROM numbers(10000);
```

После вставки была выполнена проверка на второй реплике:

```sql
SELECT count()
FROM events
WHERE event_type = 'failover_a';
```

Вторая реплика успешно получила новые данные, так как она оставалась активной и была подключена к Keeper.

Затем третья реплика была запущена обратно:

```bash
docker compose start clickhouse3
```

После запуска третья реплика автоматически начала догонять пропущенные данные из журнала репликации Keeper.

Для проверки состояния очереди использовался запрос:

```sql
SELECT
    replica_name,
    queue_size,
    inserts_in_queue,
    merges_in_queue
FROM system.replicas
WHERE table = 'events';
```

После завершения синхронизации значение `queue_size` стало равно `0`.

Вывод по эксперименту A:

ClickHouse корректно обработал временную потерю одной реплики. После восстановления реплика автоматически синхронизировалась и догнала актуальное состояние данных.


## 9. Эксперимент B — потеря Keeper-узла

Во втором эксперименте была проверена устойчивость Keeper-кворума.

Сначала был остановлен один узел Keeper:

```bash
docker compose stop keeper3
```

После остановки одного узла в кворуме осталось два узла из трёх. Этого достаточно для сохранения большинства.

Проверка состояния Keeper:

```bash
echo ruok | nc keeper1 9181
echo ruok | nc keeper2 9181
```

Оставшиеся узлы возвращали:

```text
imok
```

После этого была выполнена вставка данных:

```sql
INSERT INTO events
SELECT
    now() AS event_time,
    'keeper_one_down' AS event_type,
    number + 200000 AS user_id,
    concat('keeper_test_', toString(number)) AS payload
FROM numbers(10000);
```

Вставка прошла успешно, так как Keeper-кворум продолжал работать.

Затем был остановлен второй узел Keeper:

```bash
docker compose stop keeper2
```

После этого в работе остался только один Keeper-узел из трёх. В такой ситуации кворум отсутствует, поэтому операции, требующие согласования через Keeper, перестают работать.

При попытке вставить новые данные возникла ошибка, связанная с недоступностью Keeper-кворума.

Пример ожидаемой ошибки:

```text
Coordination error
Connection loss
Keeper exception
```

При этом чтение уже существующих данных продолжило работать:

```sql
SELECT count() FROM events;
```

Это объясняется тем, что `SELECT` читает локальные данные с реплики и не требует записи в лог репликации Keeper.

Вывод по эксперименту B:

При потере одного Keeper-узла кластер продолжает работать, так как сохраняется большинство. При потере двух Keeper-узлов кворум теряется, поэтому новые записи в реплицированные таблицы становятся невозможны. При этом локальное чтение данных остаётся доступным.


## 10. Эксперимент C — конфликт данных

В третьем эксперименте была проверена ситуация, при которой одна из реплик временно недоступна во время вставки данных.

Была остановлена вторая реплика:

```bash
docker compose stop clickhouse2
```

После этого в первую реплику были вставлены новые данные:

```sql
INSERT INTO events
SELECT
    now() AS event_time,
    'conflict_test' AS event_type,
    number + 300000 AS user_id,
    concat('conflict_test_', toString(number)) AS payload
FROM numbers(10000);
```

Затем вторая реплика была запущена обратно:

```bash
docker compose start clickhouse2
```

После запуска реплика получила пропущенные записи из журнала репликации.

Проверка:

```sql
SELECT count()
FROM events
WHERE event_type = 'conflict_test';
```

Количество строк на всех репликах совпало.

Вывод по эксперименту C:

ClickHouse не допускает конфликтов данных в обычном сценарии репликации `ReplicatedMergeTree`, так как порядок операций фиксируется через лог в Keeper. Реплика, которая была временно недоступна, после восстановления не создаёт собственную независимую версию данных, а догоняет состояние по журналу репликации.


## 11. Проверка system.replication_queue

Во время восстановления остановленной реплики была проверена таблица:

```sql
SELECT *
FROM system.replication_queue
WHERE table = 'events'
FORMAT Vertical;
```

Результат был сохранён в файл:

```text
checks/replication_queue.txt
```

Таблица `system.replication_queue` показывает задачи, которые реплика должна выполнить для синхронизации:

* получение новых частей данных;
* применение операций из журнала репликации;
* выполнение merge-операций;
* обработку очереди вставок.

Во время синхронизации в таблице могли отображаться задачи типа `GET_PART`, `MERGE_PARTS` или другие операции. После завершения синхронизации очередь стала пустой, что дополнительно подтверждает успешное восстановление реплики.


## 12. Структура репозитория

В результате выполнения работы была подготовлена следующая структура проекта:

```text
idz3/
├── README.md
├── docker-compose.yml
├── config/
│   ├── keeper/
│   │   ├── keeper1.xml
│   │   ├── keeper2.xml
│   │   └── keeper3.xml
│   └── clickhouse/
│       ├── cluster.xml
│       ├── node1_macros.xml
│       ├── node2_macros.xml
│       └── node3_macros.xml
├── sql/
│   ├── 01_create_table.sql
│   └── 02_insert_data.sql
├── scripts/
│   └── generate_events.sh
└── checks/
    ├── keeper_health.txt
    ├── replicas_status_node1.txt
    ├── replicas_status_node2.txt
    ├── replicas_status_node3.txt
    ├── experiment_a.txt
    ├── experiment_b.txt
    ├── experiment_c.txt
    └── replication_queue.txt
```

## 13. Коммиты

Работа была разбита на несколько осмысленных коммитов.

Пример структуры коммитов:

```bash
git commit -m "feat(idz3): add docker-compose with ClickHouse and Keeper nodes"
git commit -m "feat(idz3): add ClickHouse cluster configuration"
git commit -m "feat(idz3): add ReplicatedMergeTree table DDL"
git commit -m "test(idz3): add replication checks"
git commit -m "test(idz3): add failover experiments"
git commit -m "docs(idz3): add final report"
```

Такой подход позволяет проследить ход выполнения лабораторной работы и отделить настройку инфраструктуры от тестов и документации.


## 14. Общий вывод

В ходе лабораторной работы был развёрнут ClickHouse-кластер с одной шардой и тремя репликами. Для координации репликации был настроен кворум ClickHouse Keeper из трёх узлов.

Была создана реплицированная таблица `events` на движке `ReplicatedMergeTree`. После вставки тестовых данных было подтверждено, что данные корректно реплицируются между всеми узлами.

Проведённые эксперименты показали:

* при остановке одной реплики кластер продолжает принимать данные;
* после восстановления остановленная реплика автоматически догоняет актуальное состояние;
* при потере одного Keeper-узла кластер продолжает работать;
* при потере большинства Keeper-узлов запись в реплицированные таблицы становится невозможной;
* чтение локальных данных остаётся доступным даже при проблемах с Keeper;
* конфликты данных не возникают, так как порядок операций определяется логом репликации в Keeper.

Таким образом, ClickHouse `ReplicatedMergeTree` совместно с ClickHouse Keeper обеспечивает отказоустойчивую и консистентную репликацию данных между узлами кластера.

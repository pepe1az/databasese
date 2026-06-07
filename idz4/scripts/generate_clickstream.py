#!/usr/bin/env python3
"""Generate clickstream rows in TSV format.

This script is optional: the repository also contains an INSERT ... SELECT
variant in sql/04_insert_clickstream.sql. Use this generator when you want
to inspect data or insert it through clickhouse-client --query with FORMAT TSV.
"""
from __future__ import annotations

import argparse
import datetime as dt
import random

EVENT_TYPES = ["view", "click", "scroll", "purchase", "login"]


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--rows", type=int, default=2_000_000)
    parser.add_argument("--users", type=int, default=500_000)
    parser.add_argument("--seed", type=int, default=81)
    args = parser.parse_args()

    random.seed(args.seed)
    now = dt.datetime.now().replace(microsecond=0)
    today = dt.date.today()

    for i in range(args.rows):
        event_date = today - dt.timedelta(days=i % 30)
        event_time = now - dt.timedelta(seconds=i % 100_000)
        user_id = i % args.users
        session_id = f"session_{i % 100_000}"
        event_type = EVENT_TYPES[i % len(EVENT_TYPES)]
        page_url = f"/page/{i % 1000}"
        duration_ms = random.randint(1, 30_000)
        print(
            f"{event_date}\t{event_time}\t{user_id}\t{session_id}\t"
            f"{event_type}\t{page_url}\t{duration_ms}"
        )


if __name__ == "__main__":
    main()

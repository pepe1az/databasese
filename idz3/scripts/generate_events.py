#!/usr/bin/env python3
import csv
import sys
from datetime import datetime, timedelta

rows = int(sys.argv[1]) if len(sys.argv) > 1 else 100000
writer = csv.writer(sys.stdout, delimiter='\t', lineterminator='\n')
event_types = ['click', 'view', 'purchase', 'login']
base = datetime.now()

for i in range(rows):
    event_time = base - timedelta(seconds=i % 100000)
    event_type = event_types[i % len(event_types)]
    user_id = i
    payload = f'payload_{i}'
    writer.writerow([event_time.strftime('%Y-%m-%d %H:%M:%S'), event_type, user_id, payload])

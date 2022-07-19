import random
import time
from datetime import datetime, timezone
from typing import List

import pendulum
import schedule
from cachetools.func import ttl_cache
from calitp.storage import AirtableGTFSDataExtract, GTFSFeedType, AirtableGTFSDataRecord
from prometheus_client import start_http_server

from .metrics import TICKS
from .tasks import fetch, huey


@ttl_cache(ttl=600)
def get_records() -> List[AirtableGTFSDataRecord]:
    latest = AirtableGTFSDataExtract.get_latest()
    print(f"pulling updated records from airtable {latest.name}")
    records = [
        record
        for record in latest.records
        if record.data_quality_pipeline and record.data != GTFSFeedType.schedule
    ]
    print(f"found {len(records)} records in airtable {latest.name}")
    return records


if __name__ == "__main__":
    print("flushing huey")

    huey.flush()
    start_http_server(8000)

    def tick(second):
        dt = datetime.now(timezone.utc).replace(second=second)
        print(f"ticking {dt}")
        TICKS.inc()
        records = get_records()
        random.shuffle(records)
        for record in records:
            fetch(
                tick=dt,
                record=record,
            )

    schedule.every().minute.at(":00").do(tick, second=0)
    schedule.every().minute.at(":20").do(tick, second=20)
    schedule.every().minute.at(":40").do(tick, second=40)

    print(f"ticking starting at {pendulum.now()}!")
    while True:
        schedule.run_pending()
        time.sleep(1)

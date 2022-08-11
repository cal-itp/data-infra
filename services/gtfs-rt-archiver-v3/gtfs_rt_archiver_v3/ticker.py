import os
import random
import time
from datetime import datetime, timezone
from typing import List

import pendulum
import schedule
import typer
from cachetools.func import ttl_cache
from calitp.storage import AirtableGTFSDataExtract, GTFSFeedType, AirtableGTFSDataRecord
from prometheus_client import start_http_server

from .metrics import TICKS
from .tasks import fetch, huey


@ttl_cache(ttl=600)
def get_records() -> List[AirtableGTFSDataRecord]:
    typer.secho("pulling updated records from airtable")
    latest = AirtableGTFSDataExtract.get_latest()
    records = [
        record
        for record in latest.records
        if record.data_quality_pipeline and record.data != GTFSFeedType.schedule
    ]
    typer.secho(f"found {len(records)} records in airtable {latest.path}")
    return records


def main(port: int = os.getenv("TICKER_PROMETHEUS_PORT", 9102)):
    start_http_server(port)

    typer.secho("flushing huey")
    huey.flush()

    def tick(second):
        start = pendulum.now()
        dt = datetime.now(timezone.utc).replace(second=second, microsecond=0)
        typer.secho(f"ticking {dt}")
        TICKS.inc()
        records = get_records()
        random.shuffle(records)
        for record in records:
            fetch(
                tick=dt,
                record=record,
            )
        typer.secho(
            f"took {(pendulum.now() - start).in_words()} to enqueue {len(records)} fetches"
        )

    schedule.every().minute.at(":00").do(tick, second=0)
    schedule.every().minute.at(":20").do(tick, second=20)
    schedule.every().minute.at(":40").do(tick, second=40)

    typer.secho(f"ticking starting at {pendulum.now()}!")
    while True:
        schedule.run_pending()
        time.sleep(1)


if __name__ == "__main__":
    typer.run(main)

import time
from datetime import datetime, timezone

import pendulum
import schedule
from calitp.storage import AirtableGTFSDataExtract, GTFSFeedType
from prometheus_client import start_http_server

from .metrics import TICKS
from .tasks import fetch, huey


if __name__ == "__main__":
    huey.flush()
    start_http_server(8000)
    records = [
        record
        for record in AirtableGTFSDataExtract.get_latest().records
        if record.data_quality_pipeline and record.data != GTFSFeedType.schedule
    ]

    def tick(second):
        dt = datetime.now(timezone.utc).replace(second=second)
        print(dt)
        TICKS.inc()
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

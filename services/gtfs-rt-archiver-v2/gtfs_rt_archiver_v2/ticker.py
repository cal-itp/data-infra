import time
from datetime import datetime, timezone

import pendulum
import schedule
from prometheus_client import start_http_server

from gtfs_rt_archiver_v2.metrics import TICKS
from .tasks import fetch, huey


def tick(second):
    dt = datetime.now(timezone.utc).replace(second=second)
    print(dt)
    TICKS.inc()
    for n in range(1_000):
        fetch(
            tick=dt,
            url="https://lbtgtfs.lbtransit.com/TMGTFSRealTimeWebService/Vehicle/VehiclePositions.pb",
            n=n,
        )


schedule.every().minute.at(":00").do(tick, second=0)
schedule.every().minute.at(":20").do(tick, second=20)
schedule.every().minute.at(":40").do(tick, second=40)

if __name__ == "__main__":
    huey.flush()
    print(f"ticking starting at {pendulum.now()}!")
    start_http_server(8000)
    while True:
        schedule.run_pending()
        time.sleep(1)

import time

import pendulum
import schedule
from prometheus_client import start_http_server

from gtfs_rt_archiver_v2.metrics import TICKS
from .models import Tick, FetchTask
from .tasks import fetch, huey


def tick(second):
    now = pendulum.now()
    dt = now.replace(second=second, microsecond=0)
    t = Tick(dt=dt)
    print(now, dt, t)
    TICKS.inc()
    for n in range(300):
        fetch(
            FetchTask(
                tick=t,
                n=n,
                url="https://lbtgtfs.lbtransit.com/TMGTFSRealTimeWebService/Vehicle/VehiclePositions.pb",
            )
        )


schedule.every().minute.at(":00").do(tick, second=0)
schedule.every().minute.at(":20").do(tick, second=20)
schedule.every().minute.at(":40").do(tick, second=40)

if __name__ == "__main__":
    huey.flush()
    print(f"ticking starting at {pendulum.now()}!")
    start_http_server(8001)
    while True:
        schedule.run_pending()
        time.sleep(1)

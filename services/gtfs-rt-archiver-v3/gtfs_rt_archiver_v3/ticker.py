import gzip
import json
import os
import random
import time
from datetime import datetime, timezone
from typing import List, Tuple

import pendulum
import schedule
import typer
from cachetools.func import ttl_cache
from calitp.storage import (
    GTFSFeedType,
    GTFSDownloadConfig,
    get_latest,
    get_fs,
    GTFSDownloadConfigExtract,
)
from prometheus_client import start_http_server

from .metrics import TICKS, AIRTABLE_CONFIGURATION_AGE
from .tasks import fetch, huey, load_secrets


@ttl_cache(ttl=300)
def get_configs() -> Tuple[pendulum.DateTime, List[GTFSDownloadConfig]]:
    typer.secho("pulling updated configs from airtable")
    latest = get_latest(GTFSDownloadConfigExtract)
    fs = get_fs()
    with fs.open(latest.path, "rb") as f:
        content = gzip.decompress(f.read())
    records = [
        GTFSDownloadConfig(**json.loads(row)) for row in content.decode().splitlines()
    ]
    configs = [
        config
        for config in records
        if config.feed_type
        in (
            GTFSFeedType.service_alerts,
            GTFSFeedType.trip_updates,
            GTFSFeedType.vehicle_positions,
        )
    ]
    age = (pendulum.now() - latest.ts).total_seconds()
    typer.secho(
        f"found {len(configs)} configs in airtable {latest.path} {age} seconds old"
    )
    AIRTABLE_CONFIGURATION_AGE.set(age)
    return latest.ts, configs


def main(
    port: int = os.getenv("TICKER_PROMETHEUS_PORT", 9102),
    load_env_secrets: bool = False,
):
    start_http_server(port)

    if load_env_secrets:
        load_secrets()

    typer.secho("flushing huey")
    huey.flush()

    def tick(second):
        start = pendulum.now()
        dt = datetime.now(timezone.utc).replace(second=second, microsecond=0)
        typer.secho(f"ticking {dt}")
        TICKS.inc()
        extracted_at, configs = get_configs()
        random.shuffle(configs)
        for config in configs:
            fetch(
                tick=dt,
                config=config,
            )
        typer.secho(
            f"took {(pendulum.now() - start).in_words()} to enqueue {len(configs)} fetches"
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

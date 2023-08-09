import gzip
import json
import os
import random
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import List, Mapping, Optional

import pendulum
import schedule  # type: ignore
import sentry_sdk
import typer
from calitp_data_infra.auth import get_secrets_by_label  # type: ignore
from calitp_data_infra.storage import (  # type: ignore
    GTFSDownloadConfig,
    GTFSDownloadConfigExtract,
    GTFSFeedType,
    get_fs,
    get_latest,
)
from prometheus_client import start_http_server

from .metrics import AIRTABLE_CONFIGURATION_AGE, TICKS
from .tasks import fetch, huey

configs: Optional[List[GTFSDownloadConfig]] = None
secrets: Optional[Mapping[str, str]] = None


def get_configs():
    global configs
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


def get_secrets():
    global secrets
    start = pendulum.now()
    secrets = get_secrets_by_label("gtfs_rt")
    typer.secho(
        f"took {(pendulum.now() - start).in_words()} to load {len(secrets)} secrets"
    )


def main(
    port: int = int(os.getenv("TICKER_PROMETHEUS_PORT", 9102)),
    touch_file: Path = Path(os.environ["LAST_TICK_FILE"]),
):
    assert isinstance(touch_file, Path)
    sentry_sdk.init(environment=os.getenv("AIRFLOW_ENV"))
    start_http_server(port)
    get_configs()
    assert configs is not None
    get_secrets()
    assert secrets is not None
    typer.secho("flushing huey")
    huey.flush()

    def tick(second: int) -> None:
        touch_file.touch()
        start = pendulum.now()
        dt = datetime.now(timezone.utc).replace(second=second, microsecond=0)
        typer.secho(f"ticking {dt}")
        TICKS.inc()
        random.shuffle(configs)
        for config in configs:
            fetch(
                tick=dt,
                config=config,
                auth_dict=secrets,
            )
        typer.secho(
            f"took {(pendulum.now() - start).in_words()} to enqueue {len(configs)} fetches"
        )

    schedule.every().minute.at(":00").do(tick, second=0)
    schedule.every().minute.at(":20").do(tick, second=20)
    schedule.every().minute.at(":40").do(tick, second=40)
    schedule.every().minute.at(":45").do(get_configs)
    schedule.every().minute.at(":45").do(get_secrets)

    typer.secho(f"ticking starting at {pendulum.now()}!")
    while True:
        schedule.run_pending()
        time.sleep(1)


if __name__ == "__main__":
    typer.run(main)

"""
Scrapes various GTFS feed aggregators and saves the present URLs in GCS.
"""
import csv
import inspect
import io
import os
from enum import Enum
from typing import Any, Callable, ClassVar, Dict, Iterator, List, Optional, Union

import backoff
import humanize
import pendulum
import requests
import typer
from calitp_data_infra.storage import (  # type: ignore
    GTFSFeedType,
    PartitionedGCSArtifact,
    get_fs,
)
from pydantic import BaseModel, ValidationError
from requests import JSONDecodeError
from tqdm import tqdm

CALITP_BUCKET__AGGREGATOR_SCRAPER = os.environ["CALITP_BUCKET__AGGREGATOR_SCRAPER"]
BASE_URL = "https://transit.land/api/v2/rest/feeds"

TRANSITLAND_FEED_TYPES: Dict[str, str] = {
    "gbfs_auto_discovery": "general_bikeshare_feed_specification",
    "mds_provider": "mobility_data_specification",
    "realtime_alerts": GTFSFeedType.service_alerts,
    "realtime_trip_updates": GTFSFeedType.trip_updates,
    "realtime_vehicle_positions": GTFSFeedType.vehicle_positions,
    "static_current": GTFSFeedType.schedule,
    "static_historic": GTFSFeedType.schedule,
    "static_planned": GTFSFeedType.schedule,
}


class GTFSFeedAggregator(str, Enum):
    mobility_database = "mobility_database"
    transitland = "transitland"


class GTFSFeedAggregatorPresence(BaseModel):
    key: str
    name: Optional[str]
    feed_url_str: str
    feed_type: Optional[str]
    raw_record: Dict[str, Any]


class GTFSFeedAggregatorScrape(PartitionedGCSArtifact):
    bucket: ClassVar[str] = CALITP_BUCKET__AGGREGATOR_SCRAPER
    table: ClassVar[str] = "gtfs_aggregator_scrape_results"
    partition_names: ClassVar[List[str]] = ["dt", "ts", "aggregator"]
    ts: pendulum.DateTime
    end: pendulum.DateTime
    aggregator_enum: GTFSFeedAggregator
    records: List[GTFSFeedAggregatorPresence]

    @property
    def dt(self) -> pendulum.Date:
        return self.ts.date()

    @property
    def aggregator(self) -> str:
        return self.aggregator_enum.value

    @property
    def content(self) -> bytes:
        return "\n".join(o.json() for o in self.records).encode()

    def save(self, fs):
        self.save_content(
            fs=fs,
            content=self.content,
            exclude={"records"},
        )


def mobility_database() -> Iterator[GTFSFeedAggregatorPresence]:
    typer.secho("fetching mobility database", fg=typer.colors.MAGENTA)
    db_url = "https://bit.ly/catalogs-csv"
    reader = csv.DictReader(io.StringIO(requests.get(db_url).text))

    for row in reader:
        yield GTFSFeedAggregatorPresence(
            key=row["mdb_source_id"],
            feed_url_str=row["urls.direct_download"],
            raw_record=row,
        )


@backoff.on_exception(
    backoff.constant,
    requests.exceptions.HTTPError,
    max_tries=2,
    interval=10,
)
def get_transitland_api(url: str, params: Dict) -> requests.Response:
    assert "apikey" not in params
    params = params.copy()
    params["apikey"] = os.environ["TRANSITLAND_API_KEY"]
    return requests.get(url, params=params)


def transitland(progress: bool = False) -> Iterator[GTFSFeedAggregatorPresence]:
    # we can't use data["meta"]["next"] directly since we want to be able to log/save the URL

    typer.secho("fetching transitland URLs", fg=typer.colors.MAGENTA)

    max_requests = 10
    rng: Union[tqdm[int], range] = range(max_requests)

    if progress:
        rng = tqdm(rng, desc=f"paging up to {max_requests} times")

    params = {"limit": 1000}

    for _ in rng:
        typer.secho(f"querying transitland api with {params}")
        response = get_transitland_api(BASE_URL, params=params)
        try:
            data = response.json()
        except JSONDecodeError:
            typer.secho(response.text, fg=typer.colors.RED)
            raise
        for feed in data["feeds"]:
            for type_str, urls in feed["urls"].items():
                if not urls:
                    continue
                for i, url in enumerate([urls] if isinstance(urls, str) else urls):
                    # (f"https://transit.land/feeds/{feed['onestop_id']}", url)
                    try:
                        yield GTFSFeedAggregatorPresence(
                            key=f"{feed['id']}_{type_str}_{i}",
                            name=feed["name"],
                            feed_url_str=url,
                            feed_type=TRANSITLAND_FEED_TYPES[type_str],
                            raw_record={type_str: urls},
                        )
                    except (KeyError, ValidationError):
                        typer.secho(str(feed), fg=typer.colors.YELLOW)
                        raise

        try:
            params["after"] = data["meta"]["after"]
        except KeyError:
            break
    else:
        typer.secho("WARNING: hit loop limit for transitland", fg=typer.colors.YELLOW)


IMPLEMENTATIONS: Dict[
    GTFSFeedAggregator, Callable[..., Iterator[GTFSFeedAggregatorPresence]]
] = {
    GTFSFeedAggregator.mobility_database: mobility_database,
    GTFSFeedAggregator.transitland: transitland,
}


def main(aggregator: GTFSFeedAggregator, dry_run: bool = False, progress: bool = False):
    gen = IMPLEMENTATIONS[aggregator]
    kwargs = {}

    if progress and "progress" in inspect.signature(gen).parameters.keys():
        kwargs["progress"] = progress

    start = pendulum.now()
    records = list(gen(**kwargs))
    end = pendulum.now()
    typer.secho(
        f"took {humanize.time.naturaldelta(end - start)} to fetch {len(records)} records"
    )

    scrape_result = GTFSFeedAggregatorScrape(
        filename="results.jsonl",
        aggregator_enum=aggregator,
        ts=start,
        end=end,
        records=records,
    )
    if dry_run:
        typer.secho(
            f"dry run; skipping upload of {humanize.naturalsize(len(scrape_result.content))}"  # noqa: E702
        )
    else:
        typer.secho(
            f"saving {len(records)} records to {scrape_result.path}",
            fg=typer.colors.GREEN,
        )
        scrape_result.save(get_fs())


if __name__ == "__main__":
    typer.run(main)

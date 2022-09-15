# ---
# python_callable: download_all
# provide_context: true
# ---
import datetime
import gzip
import json
import logging
import traceback
from typing import List, Optional, ClassVar

import humanize
import pandas as pd
import pendulum
from airflow.models import Variable
from airflow.utils.db import create_session
from airflow.utils.email import send_email
from calitp.config import is_development
from calitp.storage import (
    get_fs,
    GTFSScheduleFeedExtract,
    GTFSFeedType,
    download_feed,
    ProcessingOutcome,
    SCHEDULE_RAW_BUCKET,
    PartitionedGCSArtifact,
    JSONL_EXTENSION,
    GTFSDownloadConfig,
    get_latest,
    GTFSDownloadConfigExtract,
)
from pydantic import validator

GTFS_FEED_LIST_ERROR_THRESHOLD = 0.95


class GTFSDownloadOutcome(ProcessingOutcome):
    config: GTFSDownloadConfig
    extract: Optional[GTFSScheduleFeedExtract]


class DownloadFeedsResult(PartitionedGCSArtifact):
    bucket: ClassVar[str] = SCHEDULE_RAW_BUCKET
    table: ClassVar[str] = "download_schedule_feed_results"
    partition_names: ClassVar[List[str]] = ["dt", "ts"]
    ts: pendulum.DateTime
    end: pendulum.DateTime
    outcomes: List[GTFSDownloadOutcome]

    @validator("filename", allow_reuse=True)
    def is_jsonl(cls, v):
        assert v.endswith(JSONL_EXTENSION)
        return v

    @property
    def dt(self) -> pendulum.Date:
        return self.ts.date()

    @property
    def successes(self) -> List[GTFSDownloadOutcome]:
        return [outcome for outcome in self.outcomes if outcome.success]

    @property
    def failures(self) -> List[GTFSDownloadOutcome]:
        return [outcome for outcome in self.outcomes if not outcome.success]

    # TODO: I dislike having to exclude the records here
    #   I need to figure out the best way to have a single type represent the "metadata" of
    #   the content as well as the content itself
    def save(self, fs):
        self.save_content(
            fs=fs,
            content="\n".join(o.json() for o in self.outcomes).encode(),
            exclude={"outcomes"},
        )


def download_all(task_instance, execution_date, **kwargs):
    start = pendulum.now()
    # https://stackoverflow.com/a/61808755
    with create_session() as session:
        auth_dict = {var.key: var.val for var in session.query(Variable)}
    print(auth_dict.keys())

    extract = get_latest(GTFSDownloadConfigExtract)

    fs = get_fs()

    with fs.open(extract.path, "rb") as f:
        content = gzip.decompress(f.read())
    records = [
        GTFSDownloadConfig(**json.loads(row)) for row in content.decode().splitlines()
    ]

    configs = [
        config for config in records if config.feed_type == GTFSFeedType.schedule
    ]
    outcomes: List[GTFSDownloadOutcome] = []

    logging.info(f"processing {len(configs)} configs")

    for i, config in enumerate(configs, start=1):
        logging.info(f"attempting to fetch {i}/{len(configs)} {config.url}")

        try:
            extract, content = download_feed(
                config=config,
                auth_dict=auth_dict,
                ts=start,
            )

            extract.save_content(fs=fs, content=content)

            outcomes.append(
                GTFSDownloadOutcome(
                    success=True,
                    config=config,
                    extract=extract,
                )
            )
        except Exception as e:
            logging.error(
                f"exception occurred while attempting to download feed {config.url}: {str(e)}\n{traceback.format_exc()}"
            )
            outcomes.append(
                GTFSDownloadOutcome(
                    success=False,
                    exception=e,
                    config=config,
                )
            )

    print(
        f"took {humanize.naturaltime(pendulum.now() - start)} to process {len(configs)} configs"
    )

    result = DownloadFeedsResult(
        ts=start,
        end=pendulum.now(),
        outcomes=outcomes,
        filename="results.jsonl",
    )

    result.save(get_fs())

    assert len(configs) == len(
        outcomes
    ), f"we somehow ended up with {len(outcomes)} outcomes from {len(configs)} configs"

    print(f"successfully fetched {len(result.successes)} of {len(configs)}")

    if result.failures:
        print(
            "Failures:\n",
            "\n".join(
                str(f.exception) or str(type(f.exception)) for f in result.failures
            ),
        )
        # use pandas begrudgingly for email HTML since the old task used it
        html_report = pd.DataFrame(f.dict() for f in result.failures).to_html(
            border=False
        )

        html_content = f"""\
    NOTE: These failures come from the v2 of the GTFS Schedule downloader.

    The following agency GTFS feeds could not be extracted on {start.to_iso8601_string()}:

    {html_report}
    """
    else:
        html_content = "All feeds were downloaded successfully!"

    if is_development():
        print(
            f"Skipping since in development mode! Would have emailed {len(result.failures)} failures."
        )
    else:
        send_email(
            to=[
                "laurie.m@jarv.us",
                "andrew.v@jarv.us",
            ],
            html_content=html_content,
            subject=(
                f"Operator GTFS Errors for {datetime.datetime.now().strftime('%Y-%m-%d')}"
            ),
        )

    success_rate = len(result.successes) / len(configs)
    if success_rate < GTFS_FEED_LIST_ERROR_THRESHOLD:
        raise RuntimeError(
            f"Success rate: {success_rate:.3f} was below error threshold: {GTFS_FEED_LIST_ERROR_THRESHOLD}"
        )


if __name__ == "__main__":
    download_all(None, pendulum.now())

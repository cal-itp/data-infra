# ---
# python_callable: download_all
# provide_context: true
# ---
import gzip
import json
import logging
from typing import ClassVar, List, Optional

import humanize
import pendulum
import sentry_sdk
from calitp_data_infra.auth import get_secrets_by_label
from calitp_data_infra.storage import (
    JSONL_EXTENSION,
    SCHEDULE_RAW_BUCKET,
    GTFSDownloadConfig,
    GTFSDownloadConfigExtract,
    GTFSFeedType,
    GTFSScheduleFeedExtract,
    PartitionedGCSArtifact,
    ProcessingOutcome,
    download_feed,
    get_fs,
    get_latest,
)
from pydantic.v1 import validator
from requests.exceptions import HTTPError

GTFS_FEED_LIST_ERROR_THRESHOLD = 0.95


class GTFSDownloadOutcome(ProcessingOutcome):
    config: GTFSDownloadConfig
    extract: Optional[GTFSScheduleFeedExtract]
    backfilled: bool = False


class DownloadFeedsResult(PartitionedGCSArtifact):
    bucket: ClassVar[str] = SCHEDULE_RAW_BUCKET
    table: ClassVar[str] = "download_schedule_feed_results"
    partition_names: ClassVar[List[str]] = ["dt", "ts"]
    ts: pendulum.DateTime
    end: pendulum.DateTime
    outcomes: List[GTFSDownloadOutcome]
    backfilled: bool = False

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
    sentry_sdk.init()
    start = pendulum.now()
    auth_dict = get_secrets_by_label("gtfs_schedule")

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

    print(f"processing {len(configs)} configs")

    for i, config in enumerate(configs, start=1):
        with sentry_sdk.push_scope() as scope:
            print(f"attempting to fetch {i}/{len(configs)} {config.url}")

            scope.set_tag("config_name", config.name)
            scope.set_tag("config_url", config.url)
            scope.set_context("config", config.dict())

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
                if isinstance(e, HTTPError):
                    scope.fingerprint = [
                        config.url,
                        str(e),
                        str(e.response.status_code),
                    ]
                else:
                    scope.fingerprint = [config.url, str(e)]
                logging.exception(
                    f"exception occurred while attempting to download feed {config.url}"
                )
                outcomes.append(
                    GTFSDownloadOutcome(
                        success=False,
                        exception=e,
                        config=config,
                    )
                )

    print(
        f"took {humanize.naturaldelta(pendulum.now() - start)} to process {len(configs)} configs"
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

        task_instance.xcom_push(
            key="download_failures",
            value=[
                json.loads(f.json()) for f in result.failures
            ],  # use the Pydantic serializer
        )

    success_rate = len(result.successes) / len(configs)
    if success_rate < GTFS_FEED_LIST_ERROR_THRESHOLD:
        raise RuntimeError(
            f"Success rate: {success_rate:.3f} was below error threshold: {GTFS_FEED_LIST_ERROR_THRESHOLD}"  # noqa: E231
        )


if __name__ == "__main__":
    download_all(None, pendulum.now())

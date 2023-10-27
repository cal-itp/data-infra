import csv
import gzip
import json
import logging
import os
from typing import ClassVar, List, Optional

import pendulum
from calitp_data_infra.storage import (
    GTFSDownloadConfig,
    PartitionedGCSArtifact,
    ProcessingOutcome,
    fetch_all_in_partition,
    get_fs,
)
from utils import GTFSScheduleFeedFile

from airflow.models import BaseOperator

SCHEDULE_PARSED_BUCKET = os.environ["CALITP_BUCKET__GTFS_SCHEDULE_PARSED"]
SCHEDULE_UNZIPPED_BUCKET = os.environ["CALITP_BUCKET__GTFS_SCHEDULE_UNZIPPED"]
GTFS_PARSE_ERROR_THRESHOLD = 0.95


class GTFSScheduleFeedJSONL(PartitionedGCSArtifact):
    bucket: ClassVar[str] = SCHEDULE_PARSED_BUCKET
    partition_names: ClassVar[List[str]] = GTFSScheduleFeedFile.partition_names
    ts: pendulum.DateTime
    extract_config: GTFSDownloadConfig
    gtfs_filename: str

    # if you try to set table directly, you get an error because it "shadows a BaseModel attribute"
    # so set as a property instead
    @property
    def table(self) -> str:
        return self.gtfs_filename

    @property
    def dt(self) -> pendulum.Date:
        return self.ts.date()

    @property
    def base64_url(self) -> str:
        return self.extract_config.base64_encoded_url


class GTFSScheduleParseOutcome(ProcessingOutcome):
    feed_file: GTFSScheduleFeedFile
    fields: Optional[List[str]]
    parsed_file: Optional[GTFSScheduleFeedJSONL]


class ScheduleParseResult(PartitionedGCSArtifact):
    bucket: ClassVar[str] = SCHEDULE_PARSED_BUCKET
    partition_names: ClassVar[List[str]] = ["dt"]
    dt: pendulum.Date
    outcomes: List[GTFSScheduleParseOutcome]

    @property
    def successes(self) -> List[GTFSScheduleParseOutcome]:
        return [outcome for outcome in self.outcomes if outcome.success]

    @property
    def table(self) -> str:
        return f"{self.outcomes[0].feed_file.table}_parsing_results"

    @property
    def failures(self) -> List[GTFSScheduleParseOutcome]:
        return [outcome for outcome in self.outcomes if not outcome.success]

    def save(self, fs):
        self.save_content(
            fs=fs,
            content="\n".join(o.json() for o in self.outcomes).encode(),
            exclude={"outcomes"},
        )


def parse_individual_file(
    fs,
    input_file: GTFSScheduleFeedFile,
    gtfs_filename: str,
) -> GTFSScheduleParseOutcome:
    logging.info(f"Processing {input_file.path}")
    field_names = None
    lines = []
    try:
        with fs.open(input_file.path, newline="", mode="r", encoding="utf-8-sig") as f:
            reader = csv.DictReader(f, restkey="calitp_unknown_fields")
            field_names = reader.fieldnames
            for line_number, row in enumerate(reader, start=1):
                row["_line_number"] = line_number
                lines.append(row)

        jsonl_content = gzip.compress(
            "\n".join(json.dumps(line) for line in lines).encode()
        )

        jsonl_file = GTFSScheduleFeedJSONL(
            ts=input_file.ts,
            extract_config=input_file.extract_config,
            filename=gtfs_filename + ".jsonl.gz",
            gtfs_filename=gtfs_filename,
        )

        jsonl_file.save_content(content=jsonl_content, fs=fs)

    except Exception as e:
        logging.warn(f"Can't process {input_file.path}: {e}")
        return GTFSScheduleParseOutcome(
            success=False,
            exception=e,
            feed_file=input_file,
            fields=field_names,
        )
    logging.info(f"Parsed {input_file.path}")
    return GTFSScheduleParseOutcome(
        success=True,
        feed_file=input_file,
        fields=field_names,
        parsed_file=jsonl_file,
    )


def parse_files(day: pendulum.datetime, input_table_name: str, gtfs_filename: str):
    fs = get_fs()
    day = pendulum.instance(day).date()
    files, missing, invalid = fetch_all_in_partition(
        cls=GTFSScheduleFeedFile,
        bucket=SCHEDULE_UNZIPPED_BUCKET,
        table=input_table_name,
        partitions={
            "dt": day,
        },
        verbose=True,
    )

    if missing or invalid:
        logging.error(f"missing: {missing}")
        logging.error(f"invalid: {invalid}")
        raise RuntimeError("found files with missing or invalid metadata; failing job")

    if not files:
        logging.warn(f"No files found for {input_table_name} for {day}")
        return

    logging.info(f"Processing {len(files)} {input_table_name} records for {day}")

    outcomes = []
    for file in files:
        outcome = parse_individual_file(fs, file, gtfs_filename)
        outcomes.append(outcome)

    assert (
        len({outcome.feed_file.table for outcome in outcomes}) == 1
    ), "somehow you're processing multiple input tables"

    result = ScheduleParseResult(filename="results.jsonl", dt=day, outcomes=outcomes)
    result.save(fs)

    assert len(files) == len(
        result.outcomes
    ), f"ended up with {len(outcomes)} outcomes from {len(files)} files"

    success_rate = len(result.successes) / len(files)
    if success_rate < GTFS_PARSE_ERROR_THRESHOLD:
        raise RuntimeError(
            f"Success rate: {success_rate:.3f} was below error threshold: {GTFS_PARSE_ERROR_THRESHOLD}"  # noqa: E231
        )


class GtfsGcsToJsonlOperator(BaseOperator):
    def __init__(self, input_table_name, gtfs_filename=None, *args, **kwargs):
        self.input_table_name = input_table_name
        self.gtfs_filename = (
            gtfs_filename if gtfs_filename else input_table_name.replace(".txt", "")
        )

        super().__init__(*args, **kwargs)

    def execute(self, context):
        print(f"Processing {context['execution_date']}")
        parse_files(
            context["execution_date"], self.input_table_name, self.gtfs_filename
        )


if __name__ == "__main__":
    lines = []
    with open("/Users/laurie/Downloads/bad_routes.txt", newline="") as f:
        reader = csv.DictReader(f)
        for row in reader:
            lines.append(row)

    content = "\n".join(json.dumps(o) for o in lines).encode()
    print(content)

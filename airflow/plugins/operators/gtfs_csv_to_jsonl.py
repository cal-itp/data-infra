import csv
import gzip
import json
import logging
import os
import pendulum

from airflow.models import BaseOperator

from calitp.storage import (
    fetch_all_in_partition,
    get_fs,
    PartitionedGCSArtifact,
    ProcessingOutcome,
    GTFSDownloadConfig,
)
from typing import ClassVar, List, Optional
from utils import GTFSScheduleFeedFile

SCHEDULE_PARSED_BUCKET = os.environ["CALITP_BUCKET__GTFS_SCHEDULE_PARSED"]
SCHEDULE_UNZIPPED_BUCKET = os.environ["CALITP_BUCKET__GTFS_SCHEDULE_UNZIPPED"]
GTFS_PARSE_ERROR_THRESHOLD = 0.95


class GTFSScheduleFeedJSONL(PartitionedGCSArtifact):
    bucket: ClassVar[str] = SCHEDULE_PARSED_BUCKET
    partition_names: ClassVar[List[str]] = GTFSScheduleFeedFile.partition_names
    ts: pendulum.DateTime
    extract_config: GTFSDownloadConfig
    input_file_path: str
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
    input_file_path: str
    fields: Optional[List[str]]
    parsed_file_path: Optional[str]


class ScheduleParseResult(PartitionedGCSArtifact):
    bucket: ClassVar[str] = SCHEDULE_PARSED_BUCKET
    table: ClassVar[str] = "parsing_results"
    partition_names: ClassVar[List[str]] = ["dt"]
    dt: pendulum.Date
    outcomes: List[GTFSScheduleParseOutcome]

    @property
    def successes(self) -> List[GTFSScheduleParseOutcome]:
        return [outcome for outcome in self.outcomes if outcome.success]

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
    field_names = []
    lines = []
    try:
        with fs.open(input_file.path, newline="", mode="r") as f:
            reader = csv.DictReader(f, restkey="calitp_unknown_fields")
            field_names = reader.fieldnames
            for row in reader:
                lines.append(row)

        jsonl_content = gzip.compress(
            "\n".join(json.dumps(line) for line in lines).encode()
        )

        jsonl_file = GTFSScheduleFeedJSONL(
            ts=input_file.ts,
            extract_config=input_file.extract_config,
            filename=gtfs_filename + ".jsonl.gz",
            input_file_path=input_file.path,
            gtfs_filename=gtfs_filename,
        )

        jsonl_file.save_content(content=jsonl_content, fs=fs)

    except Exception as e:
        logging.warn(f"Can't process {input_file.path}: {e}")
        return GTFSScheduleParseOutcome(
            success=False,
            exception=e,
            input_file_path=input_file.path,
            fields=field_names,
        )
    logging.info(f"Parsed {input_file.path}")
    return GTFSScheduleParseOutcome(
        success=True,
        input_file_path=input_file.path,
        fields=field_names,
        parsed_file=jsonl_file.path,
    )


def parse_files(day: pendulum.datetime, input_table_name: str, gtfs_filename: str):
    fs = get_fs()
    day = pendulum.instance(day).date()
    files = fetch_all_in_partition(
        cls=GTFSScheduleFeedFile,
        bucket=SCHEDULE_UNZIPPED_BUCKET,
        table=input_table_name,
        fs=fs,
        partitions={
            "dt": day,
        },
        verbose=True,
    )

    logging.info(f"Identified {len(files)} records for {day}")
    outcomes = []
    for file in files:
        outcome = parse_individual_file(fs, file, gtfs_filename)
        outcomes.append(outcome)

    result = ScheduleParseResult(filename="results.jsonl", dt=day, outcomes=outcomes)
    result.save(fs)

    assert len(files) == len(
        result.outcomes
    ), f"ended up with {len(outcomes)} outcomes from {len(files)} files"

    success_rate = len(result.successes) / len(files)
    if success_rate < GTFS_PARSE_ERROR_THRESHOLD:
        raise RuntimeError(
            f"Success rate: {success_rate:.3f} was below error threshold: {GTFS_PARSE_ERROR_THRESHOLD}"
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

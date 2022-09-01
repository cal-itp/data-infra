import csv
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
)
from typing import ClassVar, List, Optional
from utils import GTFSScheduleFeedFile

SCHEDULE_PARSED_BUCKET = os.environ["CALITP_BUCKET__GTFS_SCHEDULE_PARSED"]
SCHEDULE_UNZIPPED_BUCKET = os.environ["CALITP_BUCKET__GTFS_SCHEDULE_UNZIPPED"]


class GTFSScheduleFeedJSONL(PartitionedGCSArtifact):
    bucket: ClassVar[str] = SCHEDULE_PARSED_BUCKET
    partition_names: ClassVar[List[str]] = GTFSScheduleFeedFile.partition_names
    ts: pendulum.DateTime
    base64_url: str
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


class GTFSScheduleParseOutcome(ProcessingOutcome):
    input_file: str
    fields: Optional[List[str]]
    parsed_file: Optional[GTFSScheduleFeedJSONL]


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
        with fs.open(input_file.path, newline="") as f:
            reader = csv.DictReader(f, restkey="calitp_unknown_fields")
            field_names = reader.fieldnames
            for row in reader:
                lines.append(row)

        jsonl_content = "\n".join(json.dumps(line) for line in lines).encode()

        jsonl_file = GTFSScheduleFeedJSONL(
            ts=input_file.ts,
            base64_url=input_file.base64_url,
            input_file_path=input_file.path,
            gtfs_filename=gtfs_filename,
        )

        jsonl_file.save_content(content=jsonl_content, fs=fs)

    except Exception as e:
        logging.warn(f"Can't process {input_file.path}: {e}")
        return GTFSScheduleParseOutcome(
            success=False, exception=e, input_file=input_file, fields=field_names
        )
    logging.info(f"Successfully unzipped {input_file.path}")
    return GTFSScheduleParseOutcome(
        success=True, input_file=input_file, fields=field_names, parsed_file=jsonl_file
    )


def parse_files(day: pendulum.datetime, input_table: str, gtfs_filename: str):
    fs = get_fs()
    day = pendulum.instance(day).date()
    files = fetch_all_in_partition(
        cls=GTFSScheduleFeedFile,
        bucket=SCHEDULE_UNZIPPED_BUCKET,
        table=input_table,
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


class GtfsGcsToJsonlOperator(BaseOperator):
    def __init__(self, date, input_table, gtfs_filename, *args, **kwargs):
        self.input_table = input_table
        self.gtfs_filename = gtfs_filename

        super().__init__(*args, **kwargs)

    def execute(self, context):
        print(f"Processing {context['execution_date']}")
        parse_files(context["execution_date"], self.input_table, self.gtfs_filename)


if __name__ == "__main__":
    lines = []
    with open("/Users/laurie/Downloads/bad_routes.txt", newline="") as f:
        reader = csv.DictReader(f)
        for row in reader:
            lines.append(row)

    content = "\n".join(json.dumps(o) for o in lines).encode()
    print(content)

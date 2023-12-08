import csv
import gzip
import json
import logging
import os
import traceback
from io import StringIO
from typing import ClassVar, List, Optional

import pendulum
from calitp_data_infra.storage import (
    GTFSDownloadConfig,
    PartitionedGCSArtifact,
    ProcessingOutcome,
    get_fs,
)
from utils import GTFSScheduleFeedFileHourly, get_schedule_files_in_hour

from airflow.models import BaseOperator

SCHEDULE_PARSED_BUCKET = os.environ["CALITP_BUCKET__GTFS_SCHEDULE_PARSED_HOURLY"]
SCHEDULE_UNZIPPED_BUCKET = os.environ["CALITP_BUCKET__GTFS_SCHEDULE_UNZIPPED_HOURLY"]
GTFS_PARSE_ERROR_THRESHOLD = 0.95


class GTFSScheduleFeedJSONL(PartitionedGCSArtifact):
    bucket: ClassVar[str] = SCHEDULE_PARSED_BUCKET
    partition_names: ClassVar[List[str]] = GTFSScheduleFeedFileHourly.partition_names
    ts: pendulum.DateTime
    extract_config: GTFSDownloadConfig
    gtfs_filename: str
    csv_dialect: Optional[
        str
    ]  # dialect would be a better name but we have an old field with that name...
    num_lines: Optional[int]

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
    feed_file: GTFSScheduleFeedFileHourly
    fields: Optional[List[str]]
    parsed_file: Optional[GTFSScheduleFeedJSONL]


class ScheduleParseResult(PartitionedGCSArtifact):
    bucket: ClassVar[str] = SCHEDULE_PARSED_BUCKET
    partition_names: ClassVar[List[str]] = ["dt", "ts"]
    ts: pendulum.DateTime
    outcomes: List[GTFSScheduleParseOutcome]

    @property
    def dt(self):
        return self.ts.date()

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


def parse_csv_str(contents: str):
    lines = []
    reader = csv.DictReader(StringIO(contents), restkey="calitp_unknown_fields")
    field_names = reader.fieldnames

    if len(field_names) == 1:
        # we probably have a tab-delimited file; check that, but proceed with default
        tab_reader = csv.DictReader(
            StringIO(contents), dialect="excel-tab", restkey="calitp_unknown_fields"
        )

        if len(tab_reader.fieldnames) > 1:
            reader = tab_reader
            field_names = tab_reader.fieldnames

    for line_number, row in enumerate(reader, start=1):
        row["_line_number"] = line_number
        lines.append(row)

    return lines, field_names, reader.dialect


def parse_individual_file(
    fs,
    input_file: GTFSScheduleFeedFileHourly,
    gtfs_filename: str,
) -> GTFSScheduleParseOutcome:
    logging.info(f"Processing {input_file.path}")
    field_names = None
    try:
        with fs.open(input_file.path, newline="", mode="r", encoding="utf-8-sig") as f:
            contents = f.read()

        lines, field_names, dialect = parse_csv_str(contents)

        num_lines = len(lines)

        jsonl_content = gzip.compress(
            "\n".join(json.dumps(line) for line in lines).encode()
        )

        del lines

        jsonl_file = GTFSScheduleFeedJSONL(
            ts=input_file.ts,
            extract_config=input_file.extract_config,
            filename=gtfs_filename + ".jsonl.gz",
            gtfs_filename=gtfs_filename,
            csv_dialect=dialect,
            num_lines=num_lines,
        )

        jsonl_file.save_content(content=jsonl_content, fs=fs)

        del jsonl_content

    except Exception as e:
        logging.warn(f"Failed to process {input_file.path}: {traceback.format_exc()}")
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


def parse_files(period: pendulum.Period, input_table_name: str, gtfs_filename: str):
    fs = get_fs()
    extract_map = get_schedule_files_in_hour(
        cls=GTFSScheduleFeedFileHourly,
        bucket=SCHEDULE_UNZIPPED_BUCKET,
        table=input_table_name,
        period=period,
    )

    if not extract_map:
        logging.warn(f"No files found for {input_table_name} for {period}")
        return

    for ts, files in extract_map.items():
        logging.info(f"Processing {len(files)} {input_table_name} records for {ts}")

        outcomes = []
        for file in files:
            outcome = parse_individual_file(fs, file, gtfs_filename)
            outcomes.append(outcome)

        assert (
            len({outcome.feed_file.table for outcome in outcomes}) == 1
        ), "somehow you're processing multiple input tables"

        result = ScheduleParseResult(filename="results.jsonl", ts=ts, outcomes=outcomes)
        result.save(fs)

        assert len(files) == len(
            result.outcomes
        ), f"ended up with {len(outcomes)} outcomes from {len(files)} files"

        success_rate = len(result.successes) / len(files)
        if success_rate < GTFS_PARSE_ERROR_THRESHOLD:
            raise RuntimeError(
                f"Success rate: {success_rate:.3f} was below error threshold: {GTFS_PARSE_ERROR_THRESHOLD}"  # noqa: E231
            )


class GtfsGcsToJsonlOperatorHourly(BaseOperator):
    def __init__(self, input_table_name, gtfs_filename=None, *args, **kwargs):
        self.input_table_name = input_table_name
        self.gtfs_filename = (
            gtfs_filename if gtfs_filename else input_table_name.replace(".txt", "")
        )

        super().__init__(*args, **kwargs)

    def execute(self, context):
        period = (
            context["data_interval_end"].subtract(microseconds=1)
            - context["data_interval_start"]
        )
        print(f"Processing {period=}")
        parse_files(
            period,
            self.input_table_name,
            self.gtfs_filename,
        )


if __name__ == "__main__":
    with open("/Users/laurie/Downloads/bad_routes.txt", newline="") as f:
        content = "\n".join(json.dumps(o) for o in csv.DictReader(f)).encode()
    print(content)

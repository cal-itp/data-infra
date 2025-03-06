import csv
import gzip
import json
import os
from io import StringIO
from typing import ClassVar, List

import pendulum
from calitp_data_infra.storage import (
    PartitionedGCSArtifact,
    fetch_all_in_partition,
    get_fs,
)
from operators.littlepay_raw_sync_feed_v3 import RawLittlepayFileExtract
from tqdm import tqdm
from tqdm.contrib.logging import logging_redirect_tqdm

from airflow.models import BaseOperator

LITTLEPAY_RAW_BUCKET = os.getenv("CALITP_BUCKET__LITTLEPAY_RAW_V3")
LITTLEPAY_PARSED_BUCKET = os.getenv("CALITP_BUCKET__LITTLEPAY_PARSED_V3")


class LittlepayFileJSONL(PartitionedGCSArtifact):
    bucket: ClassVar[str] = LITTLEPAY_PARSED_BUCKET
    partition_names: ClassVar[List[str]] = ["instance", "extract_filename", "ts"]
    extract: RawLittlepayFileExtract

    @property
    def table(self) -> str:
        return self.extract.table

    @property
    def instance(self) -> str:
        return self.extract.instance

    @property
    def extract_filename(self) -> str:
        return self.extract.filename

    @property
    def ts(self) -> pendulum.DateTime:
        return self.extract.ts


def parse_raw_file(file: RawLittlepayFileExtract, fs):
    # mostly stolen from the Schedule job, we could probably abstract this
    # assume this is PSV for now, but we could sniff the delimiter
    filename, extension = os.path.splitext(file.filename)
    assert extension == ".psv"
    with fs.open(file.path) as f:
        reader = csv.DictReader(
            StringIO(f.read().decode("utf-8-sig")),
            restkey="calitp_unknown_fields",
            delimiter="|",
        )
    lines = [
        {**row, "_line_number": line_number}
        for line_number, row in enumerate(reader, start=1)
    ]
    jsonl_file = LittlepayFileJSONL(
        extract=file,
        filename=f"{filename}.jsonl.gz",
    )
    jsonl_file.save_content(
        content=gzip.compress("\n".join(json.dumps(line) for line in lines).encode()),
        fs=fs,
    )


class LittlepayToJSONLV3(BaseOperator):
    template_fields = ()

    def __init__(
        self,
        *args,
        instance: str,
        **kwargs,
    ):
        self.instance = instance
        super().__init__(**kwargs)

    def execute(self, context):
        assert LITTLEPAY_RAW_BUCKET is not None and LITTLEPAY_PARSED_BUCKET is not None

        fs = get_fs()

        # TODO: this could be worth splitting into separate tasks
        entities = [
            "authorisations",
            # renamed based on v3 table name changes
            "customer-funding-sources",
            "device-transaction-purchases",
            # this was already using the new name? verify that this is correct
            "device-transactions",
            "micropayment-adjustments",
            "micropayment-device-transactions",
            "micropayments",
            # this was also renamed based on schema changes
            "products",
            "refunds",
            "settlements",
            # this is new? handle in create_external_tables?
            "terminal-device-transactions",
        ]

        with logging_redirect_tqdm():
            for entity in tqdm(entities):
                files_to_process: List[RawLittlepayFileExtract]
                # This is not very efficient but it should be approximately 1 file per day
                # since the instance began
                files_to_process, _, _ = fetch_all_in_partition(
                    cls=RawLittlepayFileExtract,
                    table=entity,
                    partitions={
                        "instance": self.instance,
                    },
                    verbose=True,
                )
                print(f"found {len(files_to_process)} files to check")

                # subtract 30 minutes because we run 30 minutes past the hour
                # in case of late-arriving data
                period = context["data_interval_end"].subtract(
                    minutes=30, microseconds=1
                ) - context["data_interval_start"].subtract(minutes=30)

                print(f"filtering files created in {period}")

                files_to_process = [
                    file for file in files_to_process if file.ts in period
                ]

                file: RawLittlepayFileExtract
                for file in tqdm(files_to_process, desc=entity):
                    parse_raw_file(file, fs=fs)

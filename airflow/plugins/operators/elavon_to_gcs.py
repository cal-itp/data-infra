import gzip
import os
from typing import ClassVar, List, Optional

import gcsfs
import pandas as pd
import paramiko
import pendulum
from calitp_data_infra.storage import (  # type: ignore
    PartitionedGCSArtifact,
    get_fs,
    make_name_bq_safe,
)

from airflow.models import BaseOperator

CALITP_BUCKET__ELAVON = os.environ["CALITP_BUCKET__ELAVON"]
CALITP__ELAVON_SFTP_PASSWORD = os.environ["CALITP__ELAVON_SFTP_PASSWORD"]
BIGQUERY_KEYFILE_LOCATION = os.environ["BIGQUERY_KEYFILE_LOCATION"]


def fetch_and_clean_from_elavon():
    """
    Download Elavon transaction records from SFTP as a DataFrame.
    """

    all_rows = pd.DataFrame()

    # Establish connection to SFTP server
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(
        hostname="34.145.56.125",
        port=2200,
        username="elavon",
        password=CALITP__ELAVON_SFTP_PASSWORD,
    )

    # Create SFTP client and navigate to data directory
    sftp_client = client.open_sftp()
    sftp_client.chdir("/data")

    for file in [x for x in sftp_client.listdir() if "zip" in x]:
        print(f"Processing file {file}")
        local_path = f"transferred_files/{file}"
        sftp_client.get(
            file, local_path
        )  # Save locally because Pandas doesn't play nice with paramiko
        if all_rows.empty:
            all_rows = pd.read_csv(local_path, delimiter="|")  # Read from local version
        else:
            all_rows = pd.concat([all_rows, pd.read_csv(local_path, delimiter="|")])

    # Save raw files to GCS
    gfs = gcsfs.GCSFileSystem(
        project="cal-itp-data-infra",
        token=BIGQUERY_KEYFILE_LOCATION,
    )
    gfs.put(lpath="transferred_files/", rpath="test-calitp-elavon-raw/", recursive=True)

    extract = ElavonExtract(
        filename="transactions.jsonl.gz",
    )

    if all_rows.empty:
        return extract

    cleaned_df = all_rows.rename(make_name_bq_safe, axis="columns")
    extract.data = cleaned_df

    return extract


class ElavonExtract(PartitionedGCSArtifact):
    bucket: ClassVar[str] = CALITP_BUCKET__ELAVON
    table: ClassVar[str] = "transactions"
    execution_ts: pendulum.DateTime = pendulum.now()
    dt: pendulum.Date = execution_ts.date()
    partition_names: ClassVar[List[str]] = ["dt", "execution_ts"]
    data: Optional[pd.DataFrame]

    class Config:
        arbitrary_types_allowed = True

    def save_to_gcs(self, fs):
        self.save_content(
            fs=fs,
            content=gzip.compress(
                self.data.to_json(
                    orient="records", lines=True, default_handler=str
                ).encode()
            ),
            exclude={"data"},
        )


class ElavonToGCSOperator(BaseOperator):
    def __init__(
        self,
        **kwargs,
    ):
        super().__init__(**kwargs)

    def execute(self, **kwargs):
        extract = fetch_and_clean_from_elavon()

        if extract.data is None:
            print("No extracts were found")
            return
        if extract.data.empty:
            print("All extracts found were empty")
            return

        fs = get_fs()
        extract.save_to_gcs(fs=fs)

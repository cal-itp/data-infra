import gzip
import os
from datetime import datetime
from typing import ClassVar, List, Optional

import pandas as pd
import paramiko
import pendulum
import typer
from calitp_data_infra.storage import (  # type: ignore
    PartitionedGCSArtifact,
    get_fs,
    make_name_bq_safe,
)

from airflow.models import BaseOperator

CALITP_BUCKET__ELAVON = os.environ["CALITP_BUCKET__ELAVON"]
CALITP__ELAVON_SFTP_PASSWORD = os.environ["CALITP__ELAVON_SFTP_PASSWORD"]


def fetch_and_clean_from_elavon(target_date):
    """
    Download Elavon transaction records from SFTP as a DataFrame.
    """

    extract = ElavonExtract(
        dt=target_date,
        execution_ts=pendulum.now(),
        filename="transactions.jsonl.gz",
    )

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

    # Only fetch zip files that were modified on the logical run date
    for file in [x for x in sftp_client.listdir() if "zip" in x]:
        if (  # paramiko client stat mimics os.stat, returning second-valued unix times
            pendulum.from_format(str(sftp_client.stat(file).st_mtime), "X").date()
            == target_date
        ):
            print(f"Processing file {file}")
            sftp_client.get(  # Save locally because Pandas doesn't play nice with paramiko
                file, f"{file}"
            )
            if all_rows.empty:
                all_rows = pd.read_csv(f"{file}", delimiter="|")
            else:
                all_rows = pd.concat(all_rows, pd.read_csv(f"{file}", delimiter="|"))

    if all_rows.empty:
        return extract

    cleaned_df = all_rows.rename(make_name_bq_safe, axis="columns")
    extract.data = cleaned_df

    return extract


class ElavonExtract(PartitionedGCSArtifact):
    bucket: ClassVar[str] = CALITP_BUCKET__ELAVON
    table: ClassVar[str] = "transactions"
    dt: pendulum.Date
    execution_ts: pendulum.DateTime
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
    template_fields = ("logical_date",)

    def __init__(
        self,
        logical_date: datetime = typer.Argument(
            ...,
            help="The date on which the file was added to the SFTP server.",
            formats=["%Y-%m-%d"],
        ),
        **kwargs,
    ):
        self.logcial_date = logical_date
        super().__init__(**kwargs)

    def execute(self, **kwargs):
        target_date = pendulum.instance(self.logical_date).date()
        extract = fetch_and_clean_from_elavon(target_date)

        if extract.data is None:
            print(f"No new extract was found for date {target_date}")
            return
        if extract.data.empty:
            print(f"Empty extract for date {target_date}")
            return

        fs = get_fs()
        extract.save_to_gcs(fs=fs)

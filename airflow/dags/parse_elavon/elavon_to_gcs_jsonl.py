# ---
# python_callable: process_elavon_data_to_jsonl
# provide_context: true
# ---
import gzip
import os
from typing import ClassVar, List, Optional

import pandas as pd
import pendulum
from calitp_data_infra.storage import (  # type: ignore
    PartitionedGCSArtifact,
    get_fs,
    make_name_bq_safe,
)

CALITP_BUCKET__ELAVON = os.environ["CALITP_BUCKET__ELAVON"]


def fetch_and_clean_from_gcs(fs):
    """
    Download raw Elavon transaction records from GCS as a DataFrame and write out
    in BigQuery-ready JSONL format after cleaning
    """

    all_rows = pd.DataFrame()

    # List raw files available from GCS
    file_and_dir_list = fs.ls("test-calitp-elavon-raw/", detail=False)
    dir_list = [x for x in file_and_dir_list if fs.isdir(x)]
    target_dir = max(dir_list)
    file_list = fs.ls(f"{target_dir}/", detail=False)

    file_list = [x for x in file_list if fs.isfile(x)]
    for file in file_list:
        print(f"Processing file {file}")

        # Save each file locally to read into Pandas
        if not os.path.exists("transferred_files"):
            os.mkdir("transferred_files")
        local_path = f"transferred_files/{file}"
        fs.get(file, local_path)

        if all_rows.empty:
            all_rows = pd.read_csv(local_path, delimiter="|")  # Read from local version
        else:
            all_rows = pd.concat([all_rows, pd.read_csv(local_path, delimiter="|")])

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


def process_elavon_data_to_jsonl(**kwargs):
    fs = get_fs()
    extract = fetch_and_clean_from_gcs(fs)

    if extract.data is None:
        print("No extracts were found in GCS")
        return
    if extract.data.empty:
        print("All extracts found in GCS were empty")
        return

    extract.save_to_gcs(fs=fs)


if __name__ == "__main__":
    process_elavon_data_to_jsonl()

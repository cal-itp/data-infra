import gzip
import os
from typing import Optional

import pandas as pd
import pendulum
from calitp_data_infra.auth import get_secret_by_name
from calitp_data_infra.storage import get_fs, make_name_bq_safe
from pyairtable import Api
from pydantic import BaseModel

from airflow.models import BaseOperator


def process_arrays_for_nulls(arr):
    """
    BigQuery doesn't allow arrays that contain null values --
    see: https://cloud.google.com/bigquery/docs/reference/standard-sql/data-types#array_nulls
    Therefore we need to manually replace nulls with falsy values according
    to the type of data in the array.
    """
    types = set(type(entry) for entry in arr if entry is not None)

    if not types:
        return []
    # use empty string for all non-numeric types
    # may need to expand this over time
    filler = -1 if types <= {int, float} else ""
    return [x if x is not None else filler for x in arr]


def make_arrays_bq_safe(raw_data):
    safe_data = {}
    for k, v in raw_data.items():
        if isinstance(v, dict):
            v = make_arrays_bq_safe(v)
        elif isinstance(v, list):
            v = process_arrays_for_nulls(v)
        safe_data[k] = v
    return safe_data


# TODO: this should use the new generic partitioned GCS artifact type once available
class AirtableExtract(BaseModel):
    air_base_id: str
    air_base_name: str
    air_table_name: str
    data: Optional[pd.DataFrame]
    extract_time: Optional[pendulum.DateTime]

    # pydantic doesn't know dataframe type
    # see https://stackoverflow.com/a/69200069
    class Config:
        arbitrary_types_allowed = True

    def fetch_from_airtable(self, personal_access_token):
        """Download an Airtable table as a DataFrame.

        Note that airtable records have rows structured as follows:
            [{"id", "fields": {colname: value, ...}, ...]

        This function applies renames in the following order.

            1. rename id
            2. rename fields
            3. apply column prefix (to columns not renamed by 1 or 2)
        """

        print(
            f"Downloading airtable data for {self.air_base_name}.{self.air_table_name}"
        )

        api = Api(personal_access_token)
        all_rows = api.table(self.air_base_id, self.air_table_name).all()
        self.extract_time = pendulum.now()

        raw_df = pd.DataFrame(
            [
                {"id": row["id"], **make_arrays_bq_safe(row["fields"])}
                for row in all_rows
            ]
        )

        self.data = raw_df.rename(make_name_bq_safe, axis="columns")

    def make_hive_path(self, bucket: str):
        if not self.extract_time:
            # extract_time is usually set when airtable_to_df is called & data is retrieved
            raise ValueError(
                "An extract time must be set before a hive path can be generated."
            )
        safe_air_table_name = (
            str.lower("_".join(self.air_table_name.split(" ")))
            .replace("-", "_")
            .replace("+", "and")
        )
        return os.path.join(
            bucket,
            f"{self.air_base_name}__{safe_air_table_name}",
            f"dt={self.extract_time.to_date_string()}",
            f"ts={self.extract_time.to_iso8601_string()}",
            f"{safe_air_table_name}.jsonl.gz",
        )

    def save_to_gcs(self, fs, bucket):
        hive_path = self.make_hive_path(bucket)
        print(f"Uploading to GCS at {hive_path}")
        assert self.data.any(None), "data does not exist, cannot save"
        fs.pipe(
            hive_path,
            gzip.compress(self.data.to_json(orient="records", lines=True).encode()),
        )
        return hive_path


class AirtableToGCSOperator(BaseOperator):
    template_fields = ("bucket",)

    def __init__(
        self,
        bucket,
        air_base_id,
        air_base_name,
        air_table_name,
        personal_access_token=None,
        **kwargs,
    ):
        """An operator that downloads data from an Airtable base
            and saves it as a JSON file hive-partitioned by date and time in Google Cloud
            Storage (GCS).

        Args:
            bucket (str): GCS bucket where the scraped Airtable will be saved.
            air_base_id (str): The underlying id of the Airtable instance being used.
            air_base_name (str): The string name of the Base.
            air_table_name (str): The table name that should be extracted from the
                Airtable Base
            personal_access_token (str, optional): The personal access token to use when downloading from airtable.
                This can be someone's personal PAT. If not provided, the environment
                variable of `CALITP_AIRTABLE_PERSONAL_ACCESS_TOKEN` is used.
        """
        self.bucket = bucket
        self.extract = AirtableExtract(
            air_base_id=air_base_id,
            air_base_name=air_base_name,
            air_table_name=air_table_name,
        )
        self.personal_access_token = personal_access_token

        super().__init__(**kwargs)

    def execute(self, **kwargs):
        personal_access_token = self.personal_access_token or get_secret_by_name(
            "CALITP_AIRTABLE_PERSONAL_ACCESS_TOKEN"
        )
        self.extract.fetch_from_airtable(personal_access_token)
        fs = get_fs()
        # inserts into xcoms
        return self.extract.save_to_gcs(fs, self.bucket)

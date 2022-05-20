import gzip
import os
import pandas as pd
import pendulum

from pyairtable import Table
from pydantic import BaseModel
from typing import Optional, Dict
from calitp import to_snakecase
from calitp.storage import get_fs

from airflow.models import BaseOperator

AIRTABLE_API_KEY = os.environ["CALITP_AIRTABLE_API_KEY"]


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


class AirtableExtract(BaseModel):
    air_base_id: str
    air_base_name: str
    air_table_name: str
    id_name: str = "__id"
    rename_fields: Dict[str, str] = {}
    column_prefix: Optional[str]
    data: Optional[pd.DataFrame]
    extract_time: Optional[pendulum.DateTime]

    # pydantic doesn't know dataframe type
    # see https://stackoverflow.com/a/69200069
    class Config:
        arbitrary_types_allowed = True

    def fetch_from_airtable(self, api_key):
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
        all_rows = Table(api_key, self.air_base_id, self.air_table_name).all()
        self.extract_time = pendulum.now("utc")

        raw_df = pd.DataFrame(
            [
                {self.id_name: row["id"], **make_arrays_bq_safe(row["fields"])}
                for row in all_rows
            ]
        )

        # rename fields follows format new_name: old_name
        final_df = raw_df.rename(
            columns={k: v for k, v in self.rename_fields.items()}
        ).pipe(to_snakecase)

        if self.column_prefix:
            new_field_names = self.rename_fields.values()
            return final_df.rename(
                columns=lambda s: s
                if (s in new_field_names or s == self.id_name)
                else f"{self.column_prefix}{s}"
            )
        self.data = final_df

    def make_hive_path(self, bucket: str):
        if not self.extract_time:
            # extract_time is usually set when airtable_to_df is called & data is retrieved
            raise ValueError(
                "An extract time must be set before a hive path can be generated."
            )
        safe_air_table_name = str.lower(
            "_".join(self.air_table_name.split(" "))
        ).replace("-", "_")
        return os.path.join(
            bucket,
            f"{self.air_base_name}__{safe_air_table_name}",
            f"dt={self.extract_time.to_date_string()}",
            f"time={self.extract_time.to_time_string()}",
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


class AirtableToWarehouseOperator(BaseOperator):

    template_fields = ("bucket",)

    def __init__(
        self,
        bucket,
        air_base_id,
        air_base_name,
        air_table_name,
        api_key=AIRTABLE_API_KEY,
        airtable_options={},
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
            airtable_options (dict): optional fields: id_name, rename_fields,
                column_prefix.
                id_name (str, optional): The name to give the ID column. Defaults to "__id".
                rename_fields (dict, optional): A mapping of raw column name from Airtable
                    (string) to desired column name (string) respectively. Defaults to
                    empty dict.
                column_prefix (str, optional): A string prefix to rename all columns with.
                    This prefix is not applied to columns affected by a rename triggered
                    from providing either `id_name` or `rename_fields`.
            api_key (str, optional): The API key to use when downloading from airtable.
                This can be someone's personal API key. If not provided, the environment
                variable of `CALITP_AIRTABLE_API_KEY` is used.
        """
        self.bucket = bucket
        self.extract = AirtableExtract(
            air_base_id=air_base_id,
            air_base_name=air_base_name,
            air_table_name=air_table_name,
            **airtable_options,
        )
        self.api_key = api_key

        super().__init__(**kwargs)

    def execute(self, **kwargs):
        self.extract.fetch_from_airtable(self.api_key)
        fs = get_fs()
        self.extract.save_to_gcs(fs, self.bucket)

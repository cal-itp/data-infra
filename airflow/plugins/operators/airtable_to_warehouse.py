import os
import pandas as pd
import pendulum

from pyairtable import Table
from pydantic import BaseModel
from slugify import slugify
from typing import Optional, Dict
from calitp import to_snakecase
from calitp.storage import get_fs

from airflow.models import BaseOperator

AIRTABLE_API_KEY = os.environ["CALITP_AIRTABLE_API_KEY"]


class AirtableExtract(BaseModel):
    air_base_id: str
    air_base_name: str
    air_table_name: str
    id_name: str = "__id"
    rename_fields: Dict[str, str] = {}
    column_prefix: Optional[str]
    data: Optional[pd.DataFrame]
    extract_time: Optional[pendulum.DateTime]

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
            [{self.id_name: row["id"], **row["fields"]} for row in all_rows]
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
        return os.path.join(
            bucket,
            f"{self.air_base_name}__{slugify(self.air_table_name, separator='_')}",
            f"dt={self.extract_time.to_date_string()}",
            f"time={self.extract_time.to_time_string()}",
            f"{slugify(self.air_table_name, separator='_')}.csv",
        )

    def save_to_gcs(self, fs, bucket):
        hive_path = self.make_hive_path(bucket)
        print(f"Uploading to GCS at {hive_path}")
        fs.pipe(hive_path, self.data.to_csv(index=False).encode())


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
            and saves it as a CSV file hive-partitioned by date and time in Google Cloud
            Storage (GCS).

        Args:
            air_base_id (str): The underlying id of the airtable instance being used.
            air_table_name (str): The table name that should be extracted from the
                airtable base
            table_name (str): The name of the table to save to in Big Query
            gcs_path (str, optional): A GCS path prefix. If not provided, no uploading
                to GCS will occur. The resulting item gets saved to GCS at the following
                path:
                    `{base_calitp_bucket}/{gcs_path}/{execution_date}/{table_name}.csv`.
            id_name (str, optional): The name to give the ID column. Defaults to "__id".
            rename_fields (dict, optional): A mapping new desired column name (string)
                to current airtable column name (string) respectively. Defaults to None.
            column_prefix (str, optional): A string prefix to rename all columns with.
                This prefix is not applied to columns affected by a rename triggered
                from providing either `id_name` or `rename_fields`. Defaults to None.
            api_key (str, optional): The API key to use when downloading from airtable.
                This can be someone's personal API key. If not provided, the environment
                variable of `CALITP_AIRTABLE_API_KEY` is used.
        """

        self.extract = AirtableExtract(
            air_base_id=air_base_id,
            air_base_name=air_base_name,
            air_table_name=air_table_name,
            **airtable_options,
        )
        self.api_key = api_key
        self.bucket = bucket
        super().__init__(**kwargs)

    def execute(self, **kwargs):
        self.extract.fetch_from_airtable(self.api_key)
        fs = get_fs()
        self.extract.save_to_gcs(fs, self.bucket)

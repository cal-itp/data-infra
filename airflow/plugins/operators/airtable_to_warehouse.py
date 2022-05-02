import pandas as pd
import re
import os

from pyairtable import Table
from pydantic import BaseModel
from typing import Optional
from calitp import save_to_gcfs, to_snakecase, write_table

from airflow.models import BaseOperator

AIRTABLE_API_KEY = os.environ["CALITP_AIRTABLE_API_KEY"]


class AirtableExtract(BaseModel):
    api_key: str
    air_base_id: str
    air_table_name: str
    id_name = "__id"
    rename_fields = {}
    column_prefix: Optional[str] = None

    def airtable_to_df(self):
        """Download an Airtable table as a DataFrame.

        Note that airtable records have rows structured as follows:
            [{"id", "fields": {colname: value, ...}, ...]

        This function applies renames in the following order.

            1. rename id
            2. rename fields
            3. apply column prefix (to columns not renamed by 1 or 2)
        """

        print(f"Downloading airtable data for {self.air_base_id}.{self.air_table_name}")
        all_rows = Table(self.api_key, self.air_base_id, self.air_table_name).all()
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
        return final_df

    def make_hive_path(self, bucket):
        pass


class AirtableToWarehouseOperator(BaseOperator):
    def __init__(
        self,
        api_key,
        air_base_id,
        air_table_name,
        id_name,
        rename_fields,
        column_prefix,
        gcs_path,
        **kwargs,
    ):
        """An operator that downloads data from an Airtable base and loads it into
            and saves it as a CSV file hive-partitioned by date in Google Cloud
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
        self.air_base_id = air_base_id
        self.air_table_name = air_table_name
        self.id_name = id_name
        self.rename_fields = rename_fields
        self.column_prefix = column_prefix
        self.api_key = api_key
        self.gcs_path = gcs_path

        self.extract = AirtableExtract(
            air_base_id, air_table_name, id_name, rename_fields, column_prefix, api_key
        )

        super().__init__(**kwargs)

    def execute(self, context):
        df = self.extract.airtable_to_df()

        if self.table_name:
            print(f"Writing table with shape: {df.shape}")
            write_table(df, self.table_name)

        if self.gcs_path:
            clean_gcs_path = re.sub(r"\/+$", "", self.gcs_path)
            gcs_file = (
                f"{clean_gcs_path}/{context['execution_date']}/{self.table_name}.csv"
            )
            print(f"Uploading to gcs at {gcs_file}")
            save_to_gcfs(df.to_csv(index=False).encode(), f"{gcs_file}", use_pipe=True)

import pandas as pd
import re
import os

from pyairtable import Table
from calitp import save_to_gcfs, to_snakecase, write_table

from airflow.models import BaseOperator


def airtable_to_df(
    air_base_id,
    air_table_name,
    id_name="__id",
    rename_fields=None,
    column_prefix=None,
    api_key=None,
):
    """Download an airtable as a DataFrame.

    Note that airtable records have rows structured as follows:
        [{"id", "fields": {colname: value, ...}, ...]

    This function applies renames in the following order.

        1. rename id
        2. rename fields
        3. apply column prefix (to columns not renamed by 1 or 2)
    """

    api_key = os.environ["CALITP_AIRTABLE_API_KEY"] if not api_key else api_key

    if rename_fields:
        if not isinstance(rename_fields, dict):
            raise TypeError("rename fields must be a dictionary")
    else:
        rename_fields = {}

    print(f"Downloading airtable data for {air_base_id}.{air_table_name}")
    all_rows = Table(api_key, air_base_id, air_table_name).all()
    raw_df = pd.DataFrame([{id_name: row["id"], **row["fields"]} for row in all_rows])

    # rename fields follows format new_name: old_name
    final_df = raw_df.rename(columns={k: v for k, v in rename_fields.items()}).pipe(
        to_snakecase
    )

    if column_prefix:
        new_field_names = rename_fields.values()
        return final_df.rename(
            columns=lambda s: s
            if (s in new_field_names or s == id_name)
            else f"{column_prefix}{s}"
        )

    return final_df


class AirtableToWarehouseOperator(BaseOperator):
    def __init__(
        self,
        air_base_id,
        air_table_name,
        table_name,
        id_name="__id",
        gcs_path=None,
        rename_fields=None,
        column_prefix=None,
        api_key=None,
        **kwargs,
    ):
        """An operator that will download data from an airtable and load it into
            BigQuery and/or save it as a CSV file with the current date in Google Cloud
            Storage (GCS).

        Args:
            air_base_id (str): The underlying id of the airtable instance being used.
            air_table_name (str): The table name that should be extracted from the
                airtable base
            table_name (str): The name of the table to save to in Big Query
            id_name (str, optional): The name to give the ID column. Defaults to "__id".
            gcs_path (str, optional): A GCS path prefix. If not provided, no uploading
                to GCS will occur. The resulting item gets saved to GCS at the following
                path:
                    `{base_calitp_bucket}/{gcs_path}/{execution_date}/{table_name}.csv`.
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
        self.table_name = table_name
        self.id_name = id_name
        self.rename_fields = rename_fields
        self.column_prefix = column_prefix
        self.api_key = api_key
        self.gcs_path = gcs_path

        super().__init__(**kwargs)

    def execute(self, context):
        df = airtable_to_df(
            self.air_base_id,
            self.air_table_name,
            self.id_name,
            self.rename_fields,
            self.column_prefix,
            self.api_key,
        )

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

import pandas as pd
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
    final_df = raw_df.rename(columns={v: k for k, v in rename_fields.items()}).pipe(
        to_snakecase
    )

    if column_prefix:
        return final_df.rename(
            columns=lambda s: s
            if (s in rename_fields or s == id_name)
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
            gcs_file = (
                f"{self.gcs_path}/{context['execution_date']}/{self.table_name}.csv"
            )
            print(f"Uploading to gcs at {gcs_file}")
            save_to_gcfs(df.to_csv(index=False).encode(), f"{gcs_file}", use_pipe=True)

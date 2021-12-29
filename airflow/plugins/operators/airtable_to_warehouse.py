import pandas as pd
import os

from pyairtable import Table
from calitp import write_table, to_snakecase

from airflow.models import BaseOperator
from airflow.utils.decorators import apply_defaults


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
    """

    api_key = os.environ["CALITP_AIRTABLE_API_KEY"] if not api_key else api_key

    if rename_fields:
        if not isinstance(rename_fields, dict):
            raise TypeError("rename fields must be a dictionary")
    else:
        rename_fields = {}

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
    @apply_defaults
    def __init__(
        self,
        air_base_id,
        air_table_name,
        table_name,
        id_name="__id",
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

        print(f"Loading table with shape: {df.shape}")
        write_table(df, self.table_name)

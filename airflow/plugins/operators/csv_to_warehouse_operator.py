import pandas as pd
import pandas_gbq

from airflow.models import BaseOperator
from airflow.utils.decorators import apply_defaults

from calitp import save_to_gcfs


def sql_df_to_gbq_schema(df, fields=None):
    """Generate a table schema that includes column descriptions"""

    bq_schema = pandas_gbq.schema.generate_bq_schema(df)

    for entry in bq_schema["fields"]:
        description = fields.get(entry["name"])
        if description is not None:
            entry["description"] = description

    return bq_schema


def csv_to_warehouse(src_uri, table_name, fields=None, dst_bucket_dir="csv"):
    df = (
        pd.read_csv(src_uri)
        .rename(
            columns=lambda s: s.lower()
            .replace(" ", "_")
            .replace("&", "_")
            .replace("(", "_")
            .replace(")", "_")
            .replace(".", "_")
            .replace("-", "_")
            .replace("/", "_")
            .replace('"', "")
            .replace("'", "")
        )
        .rename(columns=lambda s: "_%s" % s if s[0].isdigit() else s)
    )

    table_schema = sql_df_to_gbq_schema(df, fields)
    project_id, table_name = table_name.split(".", 1)

    save_to_gcfs(
        df.to_csv(index=False).encode(),
        f"{dst_bucket_dir}/{table_name}.csv",
        use_pipe=True,
    )

    pandas_gbq.to_gbq(
        df,
        table_name,
        project_id,
        table_schema=table_schema["fields"],
        if_exists="replace",
    )


class CsvToWarehouseOperator(BaseOperator):
    template_fields = ("src_uri", "table_name")

    @apply_defaults
    def __init__(
        self, src_uri, table_name, fields=None, dst_bucket_dir="csv", *args, **kwargs
    ):
        super().__init__(*args, **kwargs)

        self.src_uri = src_uri
        self.table_name = table_name
        self.dst_bucket_dir = dst_bucket_dir

        # expected to be a dict of {<column_name>: <description>}
        self.fields = fields if fields is not None else {}

    def execute(self, context):
        csv_to_warehouse(
            self.src_uri, self.table_name, self.fields, self.dst_bucekt_dir
        )

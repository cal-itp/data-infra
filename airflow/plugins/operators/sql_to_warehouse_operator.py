from airflow.models import BaseOperator
from airflow.contrib.hooks.bigquery_hook import BigQueryHook
from googleapiclient.errors import HttpError
from airflow import AirflowException

from calitp import format_table_name, sql_patch_comments


class SqlToWarehouseOperator(BaseOperator):
    template_fields = ("sql",)

    def __init__(
        self,
        sql,
        dst_table_name,
        bigquery_conn_id="bigquery_default",
        create_disposition="CREATE_IF_NEEDED",
        fields=None,
        **kwargs,
    ):
        self.sql = sql
        self.dst_table_name = dst_table_name
        self.bigquery_conn_id = bigquery_conn_id
        self.create_disposition = create_disposition
        self.fields = fields if fields is not None else {}
        super().__init__(**kwargs)

    def execute(self, context):
        """Create a table based on a sql query, then patch in column descriptions."""

        # create table from sql query -----------------------------------------

        full_table_name = format_table_name(self.dst_table_name)
        print(full_table_name)

        # TODO: replace bq_hook with google.cloud.bigquery (or pybigquery)
        bq_hook = BigQueryHook(bigquery_conn_id=self.bigquery_conn_id)
        conn = bq_hook.get_conn()
        cursor = conn.cursor()

        print(self.sql)

        # table_resource = {
        #    "tableReference": {"table_id": table_id},
        #    "materializedView": {"query": self.sql}
        # }

        # bigquery.Table.from_api_repr(table_resource)

        try:
            cursor.run_query(
                sql=self.sql,
                destination_dataset_table=full_table_name,
                write_disposition="WRITE_TRUNCATE",
                create_disposition=self.create_disposition,
                use_legacy_sql=False,
            )

            self.log.info(
                "Query table as created successfully: {}".format(full_table_name)
            )
        except HttpError as err:
            raise AirflowException("BigQuery error: %s" % err.content)

        # patch in comments ---------------------------------------------------

        sql_patch_comments(full_table_name, self.fields)

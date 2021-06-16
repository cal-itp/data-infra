import inspect

from airflow.operators import PythonOperator
from calitp import format_table_name, sql_patch_comments


class PythonToWarehouseOperator(PythonOperator):
    template_fields = (*PythonOperator.template_fields, "table_name")

    _gusty_parameters = (
        *inspect.signature(PythonOperator.__init__).parameters.keys(),
        "table_name",
        "fields",
    )

    def __init__(
        self, table_name, fields=None, **kwargs,
    ):
        super().__init__(**kwargs)

        self.table_name = table_name
        self.fields = fields if fields is not None else {}

    def execute(self, context):

        # excutes python_callable
        print("Executing file")
        super().execute(context)

        print("Updating comments from yaml fields")
        print(self.fields)
        sql_patch_comments(format_table_name(self.table_name), self.fields)

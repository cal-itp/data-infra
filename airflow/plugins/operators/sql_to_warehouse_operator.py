from airflow.models import BaseOperator

from calitp.config import format_table_name
from calitp.sql import sql_patch_comments, write_table
from calitp import get_engine
from testing import Tester


class SqlToWarehouseOperator(BaseOperator):
    template_fields = ("sql",)

    def __init__(
        self,
        sql,
        dst_table_name,
        create_disposition=None,
        fields=None,
        tests={},
        **kwargs,
    ):

        self.sql = sql
        self.dst_table_name = dst_table_name
        self.fields = fields if fields is not None else {}
        self.tests = tests
        super().__init__(**kwargs)

    def execute(self, context):
        """Create a table based on a sql query, then patch in column descriptions."""

        table_name = self.dst_table_name

        # create table from sql query -----------------------------------------

        write_table(self.sql, table_name=table_name, verbose=True)

        self.log.info("Query table as created successfully")

        # patch in comments ---------------------------------------------------

        sql_patch_comments(format_table_name(table_name), self.fields)

        # testing -------------------------------------------------------------

        if self.tests != {}:
            tester = Tester.from_tests(
                get_engine(), format_table_name(table_name), self.tests
            )

            print("Checking test results...")
            print("\n" + repr(tester.get_test_results()))
            assert tester.all_passed(), "Tests failed"

            print("Tests passed")

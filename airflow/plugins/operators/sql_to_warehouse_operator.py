from airflow.models import BaseOperator

from calitp.config import format_table_name
from calitp.sql import sql_patch_comments, write_table, get_table
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
        fields_from=None,
        tests=None,
        **kwargs,
    ):

        self.sql = sql
        self.dst_table_name = dst_table_name
        self.fields = fields if fields is not None else {}
        self.fields_from = fields_from
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

        # fields_from ---------------------------------------------------------

        if self.fields_from is not None:
            # Ensure we are only patching comments for fields
            # that exist within the destination table
            dst_table_fields = get_table(format_table_name(table_name)).columns.keys()

            fields_to_add = {}
            for table in self.fields_from.keys():
                contents = self.fields_from[table]
                table_res = get_table(format_table_name(table))
                if isinstance(contents, list):
                    table_fields = {
                        k: table_res.columns[k].comment
                        for k in table_res.columns.keys()
                        if k in contents
                        and k not in fields_to_add.keys()
                        and k not in self.fields.keys()
                        and k in dst_table_fields
                    }
                elif contents == "any":
                    table_fields = {
                        k: table_res.columns[k].comment
                        for k in table_res.columns.keys()
                        if k not in fields_to_add.keys()
                        and k not in self.fields.keys()
                        and k in dst_table_fields
                    }
                else:
                    raise NotImplementedError(
                        "This is not an accepted fields_from option: " + repr(contents)
                    )
                fields_to_add.update(table_fields)
            print("Adding fields from existing tables:")
            print(fields_to_add)
            sql_patch_comments(format_table_name(table_name), fields_to_add)

        # testing -------------------------------------------------------------

        print(self.tests)
        if self.tests is not None:
            tester = Tester.from_tests(
                get_engine(), format_table_name(table_name), self.tests
            )

            print("Checking test results...")
            print("\n" + repr(tester.get_test_results()))
            assert tester.all_passed(), "Tests failed"

            print("Tests passed")

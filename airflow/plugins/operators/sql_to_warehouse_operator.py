from airflow.models import BaseOperator
from itertools import chain

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

        if not self.fields_from:
            sql_patch_comments(format_table_name(table_name), self.fields)

        # fields_from ---------------------------------------------------------

        if self.fields_from:
            # Ensure we are only patching comments for fields
            # that exist within the destination table
            dst_table_fields = set(
                get_table(format_table_name(table_name)).columns.keys()
            )

            # iterate over fields_from tables to inherit additional column descriptions.
            parent_cols_raw = []
            for table, contents in self.fields_from.items():
                parent_table = get_table(format_table_name(table))
                parent_fields = set(parent_table.columns.keys())

                shared_cols = dst_table_fields & parent_fields

                if isinstance(contents, list):
                    # check whether columns were specified that are not shared
                    not_in_dst_table = set(contents) - shared_cols
                    if not_in_dst_table:
                        raise KeyError(
                            "Field description columns not in result: %s"
                            % not_in_dst_table
                        )

                    # add specified column comments from parent
                    table_fields = {
                        k: parent_table.columns[k].comment for k in contents
                    }

                elif contents == "any":
                    table_fields = {
                        k: parent_table.columns[k].comment for k in shared_cols
                    }

                else:
                    raise NotImplementedError(
                        "This is not an accepted fields_from option: " + repr(contents)
                    )

                parent_cols_raw.append(table_fields)

            # unpack all parent columns into a dictionary, keeping earliest specified
            # by creating a list of all items sorted in reverse.
            parent_rev_items = chain(*reversed([d.items() for d in parent_cols_raw]))
            parent_fields = dict(parent_rev_items)

            fields_to_add = {**parent_fields, **self.fields}

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

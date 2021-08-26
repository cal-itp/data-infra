import pandas as pd

# check_null
null_query_template = """
SELECT
    '{field}' AS field,
    'check_null' AS test,
    n_nulls = 0 AS passed
FROM (
    SELECT
        SUM(CASE WHEN {field} is NULL then 1 ELSE 0 END) AS n_nulls
    FROM {table}
)
"""

# check_unique
unique_query_template = """
SELECT
    '{field}' AS field,
    'check_unique' AS test,
    n_rows = n_unique AS passed
FROM (
    SELECT
        SUM(count_n) AS n_rows,
        SUM(CASE WHEN n = 1 then count_n ELSE 0 END) AS n_unique
    FROM (
        SELECT
            n,
            COUNT(*) AS count_n
        FROM (
            SELECT
                {field},
                COUNT(*) AS n
            FROM {table}
            GROUP BY 1
        )
        GROUP BY 1
    )
)
"""

# check_composite_unique
composite_unique_query_template = """
SELECT
    '{field}' AS field,
    'check_composite_unique' AS test,
    n_rows = n_unique AS passed
FROM (
    SELECT
        SUM(count_n) AS n_rows,
        SUM(CASE WHEN n = 1 then count_n ELSE 0 END) AS n_unique
    FROM (
        SELECT
            n,
            COUNT(*) AS count_n
        FROM (
            SELECT
                {field},
                COUNT(*) AS n
            FROM {table}
            GROUP BY {field}
        )
        GROUP BY 1
    )
)
"""


def run_test(test_name, conn, fields, table, query_template, composite=False):

    if composite:
        query = query_template.format(field=", ".join(fields), table=table)
    else:
        query = "\nUNION ALL\n".join(
            [query_template.format(field=f, table=table) for f in fields]
        )

    results = pd.read_sql(con=conn, sql=query)

    return {
        "test_name": test_name,
        "nb_tests": len(results),
        "nb_passed": len(results[results.passed]),
        "all_passed": len(results) == len(results[results.passed]),
        "results_df": results,
    }


def handle_tests(engine, table, tests):
    if tests != {}:
        with engine.connect() as conn:
            try:
                tester = Tester(conn, table)
                for test, fields in tests.items():
                    test_func = getattr(tester, test)
                    test_func(fields)
            finally:
                conn.close()
        return {
            "all_passed": tester.all_passed(),
            "test_results": tester.get_test_results(),
        }
    else:
        return {"all_passed": True, "test_results": None}


class Tester:
    def __init__(self, conn, table):
        self.conn = conn
        self.table = table
        self.test_results = {}

    def check_unique(self, fields):
        res = run_test(
            "check_unique",
            conn=self.conn,
            fields=fields,
            table=self.table,
            query_template=unique_query_template,
        )

        self.test_results["check_unique"] = res

    def check_null(self, fields):
        res = run_test(
            "check_null",
            conn=self.conn,
            fields=fields,
            table=self.table,
            query_template=null_query_template,
        )

        self.test_results["check_null"] = res

    def check_composite_unique(self, fields):
        res = run_test(
            "check_composite_unique",
            conn=self.conn,
            fields=fields,
            table=self.table,
            query_template=composite_unique_query_template,
            composite=True,
        )

        self.test_results["check_composite_unique"] = res

    def all_passed(self):
        if self.test_results == {}:
            return True
        else:
            return all([v["all_passed"] for k, v in self.test_results.items()])

    def get_test_results(self):
        if self.test_results == {}:
            return None
        else:
            return pd.concat([v["results_df"] for k, v in self.test_results.items()])

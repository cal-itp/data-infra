import pandas as pd

RESULT_FIELDS = ["field", "test", "passed"]

# check_null
null_query_template = """
SELECT
    '{field}' AS field,
    '{test}' AS test,
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
    '{test}' AS test,
    n_rows = n_unique AS passed
FROM (
    SELECT
        COUNT(*) AS n_rows,
        COUNT(DISTINCT {field}) AS n_unique
    FROM {table}
)
"""

# check_composite_unique
composite_unique_query_template = """
SELECT
    '{field}' AS field,
    '{test}' AS test,
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

# check_empty
empty_query_template = """
SELECT
    '{field}' AS field,
    '{test}' AS test,
    n_rows = 0 AS passed
FROM (
    SELECT
        COUNT(*) AS n_rows
    FROM {table}
)
"""


def run_test(test_name, engine, fields, table, query_template, composite=False):

    if composite:
        query = query_template.format(
            field=", ".join(fields), table=table, test=test_name
        )
    else:
        query = "\nUNION ALL\n".join(
            [
                query_template.format(field=f, table=table, test=test_name)
                for f in fields
            ]
        )

    results = pd.read_sql(con=engine, sql=query)

    return {
        "test_name": test_name,
        "nb_tests": len(results),
        "nb_passed": len(results[results.passed]),
        "all_passed": len(results) == len(results[results.passed]),
        "results_df": results,
    }


class Tester:
    def __init__(self, engine, table):
        self.engine = engine
        self.table = table
        self.test_results = {}

    def check_unique(self, fields):
        res = run_test(
            "check_unique",
            engine=self.engine,
            fields=fields,
            table=self.table,
            query_template=unique_query_template,
        )

        self.test_results["check_unique"] = res

    def check_null(self, fields):
        res = run_test(
            "check_null",
            engine=self.engine,
            fields=fields,
            table=self.table,
            query_template=null_query_template,
        )

        self.test_results["check_null"] = res

    def check_composite_unique(self, fields):
        res = run_test(
            "check_composite_unique",
            engine=self.engine,
            fields=fields,
            table=self.table,
            query_template=composite_unique_query_template,
            composite=True,
        )

        self.test_results["check_composite_unique"] = res

    def check_empty(self, fields):
        res = run_test(
            "check_empty",
            engine=self.engine,
            fields=fields,
            table=self.table,
            query_template=empty_query_template,
            composite=False,
        )

        self.test_results["check_empty"] = res

    def all_passed(self):
        if self.test_results == {}:
            return True
        else:
            return all([v["all_passed"] for k, v in self.test_results.items()])

    def get_test_results(self):
        if self.test_results == {}:
            return pd.DataFrame(columns=RESULT_FIELDS)
        else:
            return pd.concat([v["results_df"] for k, v in self.test_results.items()])

    @classmethod
    def from_tests(cls, engine, table, tests):
        tester = cls(engine, table)
        if tests != {}:
            for test, fields in tests.items():
                test_func = getattr(tester, test)
                test_func(fields)

        return tester

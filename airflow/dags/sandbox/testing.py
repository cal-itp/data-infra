# ---
# dependencies:
#     - op_sql_query
# ---

from calitp import get_engine


def run_test(test_name, conn, fields, table, query_template, composite=False):
    import pandas as pd

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
            GROUP BY {field}
        )
        GROUP BY 1
    )
)
"""

# test case
fields = ["x", "g"]
table = "sandbox.sql_query"

conn = get_engine().connect()

try:
    check_null = run_test(
        "check_null",
        conn=conn,
        fields=fields,
        table=table,
        query_template=null_query_template,
    )
    check_unique = run_test(
        "check_unique",
        conn=conn,
        fields=fields,
        table=table,
        query_template=unique_query_template,
    )
    check_composite_unique = run_test(
        "check_composite_unique",
        conn=conn,
        fields=fields,
        table=table,
        query_template=composite_unique_query_template,
        composite=True,
    )
    print(check_null)
    print(check_unique)
    print(check_composite_unique)
finally:
    conn.close()

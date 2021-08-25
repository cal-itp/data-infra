# ---
# dependencies:
#     - op_sql_query
# ---

from calitp import get_engine

# check_unique

# query template
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


def check_unique(conn, fields, table, unique_query_template=unique_query_template):
    import pandas as pd

    unique_query = "\nUNION ALL\n".join(
        [unique_query_template.format(field=f, table=table) for f in fields]
    )

    results = pd.read_sql(con=conn, sql=unique_query)

    return {
        "test_type": "check_unique",
        "nb_tests": len(results),
        "nb_passed": len(results[results.passed]),
        "all_passed": len(results) == len(results[results.passed]),
        "results_df": results,
    }


# test case
fields = ["x", "g"]
table = "sandbox.sql_query"

conn = get_engine().connect()

try:
    res = check_unique(conn=conn, fields=fields, table=table)
    print(res)
finally:
    conn.close()

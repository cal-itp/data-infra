# ---
# dependencies:
#     - op_sql_query
# ---
from calitp import get_engine
from testing import Tester

# test case
fields = ["x", "g"]
table = "sandbox.sql_query"

conn = get_engine().connect()
tester = Tester(conn, table)
try:
    tester.check_unique(fields)
    tester.check_null(fields)
    tester.check_composite_unique(fields)
    print(tester.get_test_results())
    print(tester.all_passed())
finally:
    conn.close()

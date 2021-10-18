import pandas as pd
from calitp import get_engine, write_table

from testing import Tester

COLNAMES = ["x", "y"]

df_has_null = pd.DataFrame([(1, None), (2, "b")], columns=COLNAMES)

df_not_uniq = pd.DataFrame([(1, "a"), (1, "b")], columns=COLNAMES)

df_not_composite_uniq = pd.DataFrame([(1, "a"), (2, "b"), (1, "a")], columns=COLNAMES)

engine = get_engine()

write_table(df_has_null, "sandbox.testing_has_null")
write_table(df_not_uniq, "sandbox.testing_not_uniq")
write_table(df_not_composite_uniq, "sandbox.testing_not_composite_uniq")

# FAIL: nulls
tester = Tester.from_tests(
    engine, "sandbox.testing_has_null", {"check_null": ["x", "y"]}
)
print(tester.get_test_results())
assert not tester.all_passed()

# PASS: no nulls
tester = Tester.from_tests(
    engine, "sandbox.testing_not_uniq", {"check_null": ["x", "y"]}
)
print(tester.get_test_results())
assert tester.all_passed()

# FAIL: x is not unique
tester = Tester.from_tests(
    engine, "sandbox.testing_not_uniq", {"check_unique": ["x", "y"]}
)
print(tester.get_test_results())
assert not tester.all_passed()

# FAIL: combo of columns not unique
tester = Tester.from_tests(
    engine, "sandbox.testing_not_composite_uniq", {"check_composite_unique": ["x", "y"]}
)
print(tester.get_test_results())
assert not tester.all_passed()

---
operator: operators.SqlToWarehouseOperator
dst_table_name: "sandbox.sql_to_warehouse"

dependencies:
  - op_python_to_warehouse
  - op_csv_to_warehouse

fields_from:
  sandbox.python_to_warehouse:
    - g
  sandbox.csv_to_warehouse: any

tests:
  check_null:
    - g
    - x
  check_composite_unique:
    - g
    - x
---

SELECT g, x
FROM
    UNNEST(["a", "b"]) g
    , UNNEST([1, 2]) x

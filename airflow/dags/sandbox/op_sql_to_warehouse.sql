---
operator: operators.SqlToWarehouseOperator
dst_table_name: "sandbox.sql_to_warehouse"
fields:
  g: The g field
  x: The x field

dependencies:
  - create_dataset

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

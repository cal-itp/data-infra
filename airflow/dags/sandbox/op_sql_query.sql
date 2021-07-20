---
operator: operators.SqlQueryOperator
dependencies:
  - create_dataset
---

CREATE OR REPLACE TABLE `sandbox.sql_query` AS (
    SELECT g, x
    FROM
        UNNEST(["a", "b"]) g
        , UNNEST([1, 2]) x
)

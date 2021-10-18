---
operator: operators.SqlToWarehouseOperator
dst_table_name: "sandbox.example_validations"
fields:
  feed_key: The primary key
  code: The validation code
  date: The date
  n_notices: The number of times the code was violated
---

WITH
nested AS (
 SELECT
    [
      STRUCT("a" as feed_key, "2021-01-01" as date, "x" as code, 2 as n_notices)
      , STRUCT("a" as feed_key, "2021-01-02" as date, "x" as code, 12 as n_notices)
      , STRUCT("b" as feed_key, "2021-01-01" as date, "x" as code, 18 as n_notices)
      , STRUCT("b" as feed_key, "2021-01-02" as date, "x" as code, 9 as n_notices)
    ] AS data
)
SELECT unnested.feed_key, unnested.date, unnested.code, unnested.n_notices FROM nested, UNNEST(nested.data) AS unnested

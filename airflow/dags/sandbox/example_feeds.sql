---
operator: operators.SqlToWarehouseOperator
dst_table_name: "sandbox.example_validations"
fields:
  feed_key: The primary key
  feed_name: The name of the origin feed
  date: The date
---

WITH
nested AS (
 SELECT
    [
      STRUCT("a" as feed_key, "x" as feed_name, "2021-01-01" as date)
      , STRUCT("a" as feed_key, "x" as feed_name, "2021-01-02" as date)
      , STRUCT("b" as feed_key, "x" as feed_name, "2021-01-01" as date)
      , STRUCT("b" as feed_key, "x" as feed_name, "2021-01-02" as date)
    ] AS data
)
SELECT unnested.feed_key, unnested.feed_name, unnested.date FROM nested, UNNEST(nested.data) AS unnested

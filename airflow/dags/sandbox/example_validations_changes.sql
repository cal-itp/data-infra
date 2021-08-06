---
operator: operators.SqlToWarehouseOperator
dst_table_name: "sandbox.example_validations_changes"
fields:
  feed_key: The primary key
  code: The validation code
  date: The date
  n_notices: The number of times the code was violated
dependencies:
  - example_validations
---

SELECT feed_key,
  code,
  date,
  n_notices,
  n_notices - LAG(n_notices)
    OVER (PARTITION BY feed_key, code ORDER BY date ASC) AS n_notices_diff
FROM `cal-itp-data-infra-staging.sandbox.example_validations`;

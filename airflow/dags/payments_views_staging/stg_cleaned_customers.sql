---
operator: operators.SqlToWarehouseOperator
dst_table_name: "payments.stg_cleaned_customers"

description: >
    This table most importantly serves as a mapping from each customer_id to a
    principal or canonical customer_id. Each customer_id with the same
    principal_customer_id should be assumed to be the same person. A customer_id
    should only have one principal_customer_id.

dependencies:
  - stg_enriched_customer_funding_source

tests:
  check_unique:
    - customer_id
  check_null:
    - principal_customer_id
---

SELECT DISTINCT
    customer_id,
    principal_customer_id,
FROM payments.stg_enriched_customer_funding_source
WHERE calitp_dupe_number = 1
    AND calitp_customer_id_rank = 1

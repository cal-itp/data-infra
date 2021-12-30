---
operator: operators.SqlToWarehouseOperator
dst_table_name: "payments.invalid_cleaned_principal_customer_ids"

description: >
  Each pricipal_customer_id should only ever have itself as a principal.

dependencies:
  - stg_cleaned_customers
---

WITH

principal_customer_ids AS (
    SELECT DISTINCT principal_customer_id
    FROM payments.stg_cleaned_customers
),

principal_customers AS (
    SELECT customer_id, principal_customer_id
    FROM payments.stg_cleaned_customers
    WHERE customer_id IN (SELECT principal_customer_id FROM principal_customer_ids)
)

SELECT *
FROM principal_customers
WHERE customer_id <> principal_customer_id

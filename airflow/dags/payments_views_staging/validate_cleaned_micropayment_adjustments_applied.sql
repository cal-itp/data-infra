---
operator: operators.SqlToWarehouseOperator
dst_table_name: "payments.invalid_cleaned_micropayment_adjustments_applied"

description: >
  Ensure that there is only one micropayment_adjustments record with applied
  set to True for each micropayment.

dependencies:
  - stg_cleaned_micropayment_adjustments

tests:
  check_empty:
    - "*"
---

SELECT micropayment_id, count(*)
FROM payments.stg_cleaned_micropayment_adjustments
WHERE applied IS True
GROUP BY micropayment_id
HAVING COUNT(*) > 1
ORDER BY COUNT(*) desc

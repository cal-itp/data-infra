---
operator: operators.SqlToWarehouseOperator
dst_table_name: "payments.invalid_payments_ride_adjustments"

description: >
  Make sure that all rides where the amount paid is not equal to the nominal
  amount have adjustments, and rides where the amount paid is equal to the
  nominal amount do not have adjustments.

dependencies:
  - payments_rides

tests:
  check_empty:
    - "*"
---

SELECT * FROM views.payments_rides
WHERE charge_amount <> nominal_amount
AND adjustment_id IS NULL

UNION ALL

SELECT * FROM views.payments_rides
WHERE charge_amount = nominal_amount
AND adjustment_id IS NOT NULL

---
operator: operators.SqlQueryOperator
dependencies:
  - micropayments
  - micropayment_device_transactions
  - micropayment_device_ids_fare_type
---
DROP TABLE IF EXISTS `views.mst_ridership_materalized`;
CREATE TABLE `views.mst_ridership_materalized`
AS (SELECT * FROM `cal-itp-data-infra.views.mst_ridership`)

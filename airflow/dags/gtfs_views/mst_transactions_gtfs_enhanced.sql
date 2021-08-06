---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.mst_transactions_gtfs_enhanced"
external_dependencies:
  - payments_loader: all
---

SELECT participant_id,
       littlepay_transaction_id,
       device_id, type,
       transaction_outcome,
       transaction_date_time_utc,
       DATETIME(transaction_date_time_utc, "America/Los_Angeles") as transaction_date_time_pacific,
       location_id,
       location_name,
       t1.route_id,
       latitude,
       longitude,
       vehicle_id,
       t2.route_long_name,
       t2.route_short_name
FROM `payments.device_transactions` as t1
 LEFT JOIN
(SELECT route_id, route_short_name, route_long_name
FROM `gtfs_schedule.routes`
WHERE calitp_itp_id = 208) as t2
ON  t1.route_id = t2.route_id
WHERE
transaction_outcome = 'allow' AND
participant_id = 'mst'

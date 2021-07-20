---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.mst_ridership"
external_dependencies:
  - payments_loader: all
---

SELECT t1.participant_id,
       t1.littlepay_transaction_id,
       t1.device_id,
       t1.type,
       t1.transaction_outcome,
       t1.transaction_date_time_utc,
       t1.transaction_date_time_pacific,
       t1.location_id,
       t1.location_name,
       t1.route_id,
       t1.latitude,
       t1.longitude,
       t1.vehicle_id,
       t1.route_long_name,
       t1.route_short_name,
       t2.charge_type,
       t2.charge_amount
FROM `views.mst_transactions_gtfs_enhanced` as t1
LEFT JOIN `payments.micropayment_device_ids_fare_type` as t2
ON t1.littlepay_transaction_id = t2.littlepay_transaction_id 
WHERE charge_type = 'complete_variable_fare' 
OR charge_type = 'flat_fare'
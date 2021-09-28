---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.mst_transactions_gtfs_enhanced"
external_dependencies:
  - payments_loader: all
---

WITH

gtfs_routes_with_participant AS (
    SELECT participant_id, route_id, route_short_name, route_long_name
    FROM `gtfs_schedule.routes`
    JOIN `views.payments_feeds` USING (calitp_itp_id, calitp_url_number)
),

device_transactions AS (
    SELECT
        participant_id,
        littlepay_transaction_id,
        device_id,
        type,
        transaction_outcome,
        transaction_date_time_utc,
        DATETIME(TIMESTAMP(transaction_date_time_utc), "America/Los_Angeles") as transaction_date_time_pacific,
        location_id,
        location_name,
        route_id,
        latitude,
        longitude,
        vehicle_id,

    FROM `payments.device_transactions`

)

SELECT
    t1.*,
    t2.route_long_name,
    t2.route_short_name
FROM device_transactions as t1
LEFT JOIN gtfs_routes_with_participant t2
    USING (participant_id, route_id)
WHERE
    transaction_outcome = 'allow'

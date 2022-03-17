---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.mst_transactions_gtfs_enhanced"

dependencies:
  - dummy_staging
  - payments_feeds
---

WITH

gtfs_routes_with_participant AS (
    SELECT participant_id, route_id, route_short_name, route_long_name, calitp_extracted_at, calitp_deleted_at
    FROM `views.gtfs_schedule_dim_routes`
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
        TRIM(route_id) as route_id,
        latitude,
        longitude,
        vehicle_id,

    FROM `payments.stg_cleaned_device_transactions`

)

SELECT
    t1.*,
    t2.route_long_name,
    t2.route_short_name
FROM device_transactions as t1
LEFT JOIN gtfs_routes_with_participant t2
    ON t1.participant_id = t2.participant_id
    AND t1.route_id = t2.route_id
    AND DATETIME(TIMESTAMP(transaction_date_time_utc)) >= t2.calitp_extracted_at
    AND DATETIME(TIMESTAMP(transaction_date_time_utc)) < t2.calitp_deleted_at
WHERE
    transaction_outcome = 'allow'

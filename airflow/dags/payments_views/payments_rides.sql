---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.payments_rides"

dependencies:
  - payments_feeds

external_dependencies:
  - payments_views_staging: all

tests:
  check_unique:
    - micropayment_id
    - littlepay_transaction_id
---

WITH

gtfs_routes_with_participant AS (
    SELECT participant_id, route_id, route_short_name, route_long_name
    FROM `gtfs_schedule.routes`
    JOIN `views.payments_feeds` USING (calitp_itp_id, calitp_url_number)
),

initial_transactions AS (
    SELECT *
    FROM `payments.stg_cleaned_micropayment_device_transactions`
    JOIN `payments.stg_cleaned_device_transactions` USING (littlepay_transaction_id)
    JOIN `payments.stg_cleaned_device_transaction_types` USING (littlepay_transaction_id)
    WHERE transaction_type IN ('single', 'on')
),

second_transactions AS (
    SELECT *
    FROM `payments.stg_cleaned_micropayment_device_transactions`
    JOIN `payments.stg_cleaned_device_transactions` USING (littlepay_transaction_id)
    JOIN `payments.stg_cleaned_device_transaction_types` USING (littlepay_transaction_id)
    WHERE transaction_type = 'off'
)

SELECT
    m.participant_id,
    m.micropayment_id,
    m.charge_type,
    m.charge_amount,
    m.nominal_amount,

    -- Common transaction info
    r.route_id,
    r.route_long_name,
    r.route_short_name,
    t1.direction,
    t1.vehicle_id,

    -- Tap on or single transaction info
    t1.littlepay_transaction_id,
    t1.device_id,
    t1.transaction_type,
    t1.transaction_outcome,
    t1.transaction_date_time_utc,
    t1.transaction_date_time_pacific,
    t1.location_id,
    t1.location_name,
    t1.latitude,
    t1.longitude,

    -- Tap off transaction info
    t2.littlepay_transaction_id AS off_littlepay_transaction_id,
    t2.device_id AS off_device_id,
    t2.transaction_type AS off_transaction_type,
    t2.transaction_outcome AS off_transaction_outcome,
    t2.transaction_date_time_utc AS off_transaction_date_time_utc,
    t2.transaction_date_time_pacific AS off_transaction_date_time_pacific,
    t2.location_id AS off_location_id,
    t2.location_name AS off_location_name,
    t2.latitude AS off_latitude,
    t2.longitude AS off_longitude

FROM `payments.stg_cleaned_micropayments` AS m
JOIN initial_transactions AS t1 USING (participant_id, micropayment_id)
JOIN gtfs_routes_with_participant AS r USING (participant_id, route_id)
LEFT JOIN second_transactions AS t2 USING (participant_id, micropayment_id)

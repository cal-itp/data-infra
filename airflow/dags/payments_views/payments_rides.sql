---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.payments_rides"

fields:
  participant_id: "Littlepay-assigned Participant ID"
  micropayment_id: "From payments.micropayments.micropayment_id"
  funding_source_vault_id: "From payments.micropayments.funding_source_vault_id"
  customer_id: "From payments.micropayments.customer_id"
  principal_customer_id: "From payments.customer_funding_source.principal_customer_id"
  bin: "From payments.customer_funding_source.bin"
  masked_pan: "From payments.customer_funding_source.masked_pan"
  card_scheme: "From payments.customer_funding_source.card_scheme"
  issuer: "From payments.customer_funding_source.issuer"
  issuer_country: "From payments.customer_funding_source.issuer_country"
  form_factor: "From payments.customer_funding_source.form_factor"
  charge_amount: "From payments.micropayments.charge_amount"
  nominal_amount: "From payments.micropayments.nominal_amount"
  charge_type: "From payments.micropayments.charge_type"
  adjustment_id: "From payments.micropayments.adjustment_id"
  adjustment_type: "From payments.micropayment_adjustments.type"
  adjustment_time_period_type: "From payments.micropayment_adjustments.time_period_type"
  adjustment_description: "From payments.micropayment_adjustments.description"
  adjustment_amount: "From payments.micropayment_adjustments.amount"
  product_id: "From payments.micropayment_adjustments.product_id"
  product_code: "From payments.product_data.product_code"
  product_description: "From payments.product_data.product_description"
  product_type: "From payments.product_data.product_type"
  route_id: "The route_id of the first tap transaction"
  route_long_name: "The route_long_name of the first tap transaction"
  route_short_name: "The route_short_name of the first tap transaction"
  direction: "The direction of the first tap transaction"
  vehicle_id: "The vehicle_id of the first tap transaction"
  littlepay_transaction_id: "The littlepay_transaction_id of the first tap transaction"
  device_id: "The device_id of the first tap transaction"
  transaction_type: "The transaction_type of the first tap transaction"
  transaction_outcome: "The transaction_outcome of the first tap transaction"
  transaction_date_time_utc: "The transaction_date_time_utc of the first tap transaction"
  transaction_date_time_pacific: "The transaction_date_time_pacific of the first tap transaction"
  location_id: "The location_id of the first tap transaction"
  location_name: "The location_name of the first tap transaction"
  latitude: "The latitude of the first tap transaction"
  longitude: "The longitude of the first tap transaction"
  off_littlepay_transaction_id: "The littlepay_transaction_id of the second tap transaction (if there is one)"
  off_device_id: "The device_id of the second tap transaction (if there is one)"
  off_transaction_type: "The transaction_type of the second tap transaction (if there is one)"
  off_transaction_outcome: "The transaction_outcome of the second tap transaction (if there is one)"
  off_transaction_date_time_utc: "The transaction_date_time_utc of the second tap transaction (if there is one)"
  off_transaction_date_time_pacific: "The transaction_date_time_pacific of the second tap transaction (if there is one)"
  off_location_id: "The location_id of the second tap transaction (if there is one)"
  off_location_name: "The location_name of the second tap transaction (if there is one)"
  off_latitude: "The latitude of the second tap transaction (if there is one)"
  off_longitude: "The longitude of the second tap transaction (if there is one)"

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

applied_adjustments AS (
    SELECT participant_id, micropayment_id, product_id, adjustment_id, type, time_period_type, description, amount
    FROM `payments.stg_cleaned_micropayment_adjustments`
    WHERE applied IS True
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

    -- Customer and funding source information
    m.funding_source_vault_id,
    m.customer_id,
    c.principal_customer_id,
    v.bin,
    v.masked_pan,
    v.card_scheme,
    v.issuer,
    v.issuer_country,
    v.form_factor,

    m.charge_amount,
    m.nominal_amount,
    m.charge_type,
    a.adjustment_id,
    a.type AS adjustment_type,
    a.time_period_type AS adjustment_time_period_type,
    a.description AS adjustment_description,
    a.amount AS adjustment_amount,
    p.product_id,
    p.product_code,
    p.product_description,
    p.product_type,

    -- Common transaction info
    CASE WHEN t1.route_id <> 'Route Z' THEN t1.route_id ELSE COALESCE(t2.route_id, 'Route Z') END AS route_id,
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
JOIN `payments.stg_cleaned_customers` AS c USING (customer_id)
LEFT JOIN `payments.stg_cleaned_customer_funding_source_vaults` AS v
    ON m.funding_source_vault_id = v.funding_source_vault_id
    AND m.transaction_time >= CAST(v.calitp_valid_at AS TIMESTAMP)
    AND m.transaction_time < CAST(v.calitp_invalid_at AS TIMESTAMP)
JOIN initial_transactions AS t1 USING (participant_id, micropayment_id)
LEFT JOIN second_transactions AS t2 USING (participant_id, micropayment_id)
LEFT JOIN applied_adjustments AS a USING (participant_id, micropayment_id)
LEFT JOIN `payments.stg_cleaned_product_data` AS p USING (participant_id, product_id)
LEFT JOIN gtfs_routes_with_participant AS r
    ON r.participant_id = m.participant_id
    AND r.route_id = (CASE WHEN t1.route_id <> 'Route Z' THEN t1.route_id ELSE COALESCE(t2.route_id, 'Route Z') END)

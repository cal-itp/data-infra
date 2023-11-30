{{ config(
    post_hook="{{ payments_row_access_policy() }}"
) }}

WITH

fct_daily_schedule_feeds AS (
    SELECT * FROM {{ ref('fct_daily_schedule_feeds') }}
),

dim_routes AS (
    SELECT * FROM {{ ref('dim_routes') }}
),

dim_agency AS (
    SELECT * FROM {{ ref('dim_agency') }}
),

dim_gtfs_datasets AS (
    SELECT * FROM {{ ref('dim_gtfs_datasets') }}
),

payments_entity_mapping AS (
    SELECT * FROM {{ ref('payments_entity_mapping') }}
),

micropayments AS (
    SELECT *
    FROM {{ ref('int_payments__micropayments_adjustments_refunds_joined') }}
),

int_payments__matched_device_transactions AS (
    SELECT *
    FROM {{ ref('int_payments__matched_device_transactions') }}
),

int_littlepay__customers AS (
    SELECT *
    FROM {{ ref('int_littlepay__customers') }}
),

int_littlepay__customer_funding_source_vaults AS (
    SELECT *
    FROM {{ ref('int_littlepay__customer_funding_source_vaults') }}
),

stg_littlepay__product_data AS (
    SELECT *
    FROM {{ ref('stg_littlepay__product_data') }}
),

participants_to_routes_and_agency AS (
    SELECT
        pf.littlepay_participant_id,
        f.date,
        r.route_id,
        r.route_short_name,
        r.route_long_name,
        a.agency_id,
        a.agency_name,
    FROM payments_entity_mapping AS pf
    LEFT JOIN dim_gtfs_datasets d
        ON pf.gtfs_dataset_source_record_id = d.source_record_id
    LEFT JOIN fct_daily_schedule_feeds AS f
        ON d.key = f.gtfs_dataset_key
    LEFT JOIN dim_routes AS r
        ON f.feed_key = r.feed_key
    LEFT JOIN dim_agency AS a
        ON r.agency_id = a.agency_id
            AND r.feed_key = a.feed_key
),

join_table AS (
    SELECT

        m.participant_id,
        m.micropayment_id,
        m.aggregation_id,

        -- Customer and funding source information
        m.funding_source_vault_id,
        m.customer_id,
        c.principal_customer_id,
        c.earliest_tap,
        v.bin,
        v.masked_pan,
        v.card_scheme,
        v.issuer,
        v.issuer_country,
        v.form_factor,

        m.charge_amount,
        m.micropayment_refund_amount AS refund_amount,
        m.aggregation_refund_amount,
        m.nominal_amount,
        m.charge_type,
        m.adjustment_id,
        m.adjustment_type,
        m.adjustment_time_period_type,
        m.adjustment_description,
        m.adjustment_amount,
        p.product_id,
        p.product_code,
        p.product_description,
        p.product_type,

--         Common transaction info
        r.route_long_name,
        r.route_short_name,
        r.agency_id,
        r.agency_name,
        device_transactions.route_id,
        device_transactions.direction,
        device_transactions.vehicle_id,
        device_transactions.littlepay_transaction_id,
        device_transactions.device_id,
        device_transactions.transaction_type,
        device_transactions.transaction_outcome,
        device_transactions.transaction_date_time_utc,
        device_transactions.transaction_date_time_pacific,
        device_transactions.location_id,
        device_transactions.location_name,
        -- TODO: these lat/long values are repeated (with and without on_ prefix)
        device_transactions.latitude,
        device_transactions.longitude,
        device_transactions.on_latitude,
        device_transactions.on_longitude,
        device_transactions.on_geography,
        device_transactions.off_device_id,
        device_transactions.off_transaction_type,
        device_transactions.off_transaction_outcome,
        device_transactions.off_transaction_date_time_utc,
        device_transactions.off_transaction_date_time_pacific,
        device_transactions.off_location_id,
        device_transactions.off_location_name,
        device_transactions.off_latitude,
        device_transactions.off_longitude,
        device_transactions.off_geography,

    FROM micropayments AS m
    LEFT JOIN int_littlepay__customers AS c
        ON m.customer_id = c.customer_id
        AND m.participant_id = c.participant_id
    LEFT JOIN int_littlepay__customer_funding_source_vaults AS v
        ON m.funding_source_vault_id = v.funding_source_vault_id
        AND m.participant_id = v.participant_id
        AND m.transaction_time >= v.calitp_valid_at
        AND m.transaction_time < v.calitp_invalid_at
    LEFT JOIN int_payments__matched_device_transactions AS device_transactions
        ON m.participant_id = device_transactions.participant_id
            AND m.micropayment_id = device_transactions.micropayment_id
    LEFT JOIN stg_littlepay__product_data AS p
        ON m.participant_id = p.participant_id
            AND m.product_id = p.product_id
    LEFT JOIN participants_to_routes_and_agency AS r
        ON r.littlepay_participant_id = m.participant_id
            -- here, can just use t1 because transaction date will be populated
            -- (don't have to handle unkowns the way we do with route_id)
            AND EXTRACT(DATE FROM TIMESTAMP(t1.transaction_date_time_utc)) = r.date
            AND r.route_id = COALESCE(t1.route_id, t2.route_id)

),

fct_payments_rides_v2 AS (
    SELECT

        * EXCEPT(form_factor),
        CASE
            WHEN form_factor IS NULL THEN 'Unidentified'
            WHEN form_factor = '' THEN 'Unidentified'
            ELSE form_factor
            END AS form_factor,
        DATETIME_DIFF(
            off_transaction_date_time_pacific,
            transaction_date_time_pacific,
            MINUTE
        ) AS duration,
        ST_DISTANCE(on_geography, off_geography) AS distance_meters,
        SAFE_CAST(transaction_date_time_pacific AS DATE) AS transaction_date_pacific,
        EXTRACT(DAYOFWEEK FROM transaction_date_time_pacific) AS day_of_week

    FROM join_table
)

SELECT * FROM fct_payments_rides_v2

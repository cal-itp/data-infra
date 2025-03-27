{{ config(materialized = 'table',
    post_hook="{{ payments_littlepay_row_access_policy() }}") }}

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

int_payments__customers AS (
    SELECT *
    FROM {{ ref('int_payments__customers') }}
),

int_payments__customer_funding_source_vaults AS (
    SELECT *
    FROM {{ ref('int_payments__customer_funding_source_vaults') }}
),

int_littlepay__unioned_product_data AS (
    SELECT *
    FROM {{ ref('int_littlepay__unioned_product_data') }}
),

participants_to_routes_and_agency AS (
    SELECT
        map.littlepay_participant_id,
        feeds.date,
        routes.route_id,
        routes.route_short_name,
        routes.route_long_name,
        agency.agency_id,
        agency.agency_name,
    FROM payments_entity_mapping AS map
    LEFT JOIN dim_gtfs_datasets AS gtfs
        ON map.gtfs_dataset_source_record_id = gtfs.source_record_id
    LEFT JOIN fct_daily_schedule_feeds AS feeds
        ON gtfs.key = feeds.gtfs_dataset_key
    LEFT JOIN dim_routes AS routes
        ON feeds.feed_key = routes.feed_key
    LEFT JOIN dim_agency AS agency
        ON routes.agency_id = agency.agency_id
            AND routes.feed_key = agency.feed_key
),

fct_payments_rides_v2 AS (
    SELECT

        micropayments.participant_id,
        micropayments.micropayment_id,
        micropayments.aggregation_id,

        -- Customer and funding source information
        micropayments.funding_source_vault_id,
        micropayments.customer_id,
        customers.principal_customer_id,
        customers.earliest_tap,
        vaults.bin,
        vaults.masked_pan,
        vaults.card_scheme,
        vaults.issuer,
        vaults.issuer_country,
        COALESCE(vaults.form_factor, "Unidentified") AS form_factor,

        micropayments.charge_amount,
        micropayments.micropayment_refund_amount AS refund_amount,
        micropayments.aggregation_refund_amount,
        micropayments.nominal_amount,
        micropayments.charge_type,
        micropayments.adjustment_id,
        micropayments.adjustment_type,
        micropayments.adjustment_time_period_type,
        micropayments.adjustment_description,
        micropayments.adjustment_amount,
        products.product_id,
        products.product_code,
        products.product_description,
        products.product_type,

        -- Common transaction info
        routes.route_long_name,
        routes.route_short_name,
        routes.agency_id,
        routes.agency_name,
        device_transactions.route_id,
        device_transactions.direction,
        device_transactions.vehicle_id,
        device_transactions.littlepay_transaction_id,
        device_transactions.off_littlepay_transaction_id,
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
        device_transactions.duration,
        device_transactions.distance_meters,
        device_transactions.transaction_date_pacific,
        device_transactions.day_of_week,
        device_transactions.distance_miles

    FROM micropayments
    LEFT JOIN int_payments__customers AS customers
        ON micropayments.customer_id = customers.customer_id
        AND micropayments.participant_id = customers.participant_id
    LEFT JOIN int_payments__customer_funding_source_vaults AS vaults
        ON micropayments.funding_source_vault_id = vaults.funding_source_vault_id
        AND micropayments.participant_id = vaults.participant_id
        AND micropayments.transaction_time >= vaults.calitp_valid_at
        AND micropayments.transaction_time < vaults.calitp_invalid_at
    LEFT JOIN int_payments__matched_device_transactions AS device_transactions
        ON micropayments.participant_id = device_transactions.participant_id
            AND micropayments.micropayment_id = device_transactions.micropayment_id
    LEFT JOIN int_littlepay__unioned_product_data AS products
        ON micropayments.participant_id = products.participant_id
            AND micropayments.product_id = products.product_id
    LEFT JOIN participants_to_routes_and_agency AS routes
        ON routes.littlepay_participant_id = micropayments.participant_id
            -- here, can just use t1 because transaction date will be populated
            -- (don't have to handle unkowns the way we do with route_id)
            AND EXTRACT(DATE FROM TIMESTAMP(device_transactions.transaction_date_time_utc)) = routes.date
            AND routes.route_id = device_transactions.route_id

)

SELECT * FROM fct_payments_rides_v2

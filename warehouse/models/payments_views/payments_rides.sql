{{ config(
    post_hook=[
" {{ create_row_access_policy(
    filter_column = 'participant_id',
    filter_value = 'mst',
    principals = ['serviceAccount:mst-payments-user@cal-itp-data-infra.iam.gserviceaccount.com']
) }}",
" {{ create_row_access_policy(
    filter_column = 'participant_id',
    filter_value = 'sacrt',
    principals = ['serviceAccount:sacrt-payments-user@cal-itp-data-infra.iam.gserviceaccount.com']
) }}",
" {{ create_row_access_policy(
    filter_column = 'participant_id',
    filter_value = 'sbmtd',
    principals = ['serviceAccount:sbmtd-payments-user@cal-itp-data-infra.iam.gserviceaccount.com']
) }}",
" {{ create_row_access_policy(
    filter_column = 'participant_id',
    filter_value = 'clean-air-express',
    principals = ['serviceAccount:clean-air-payments-user@cal-itp-data-infra.iam.gserviceaccount.com']
) }}",
" {{ create_row_access_policy(
    filter_column = 'participant_id',
    filter_value = 'ccjpa',
    principals = ['serviceAccount:ccjpa-payments-user@cal-itp-data-infra.iam.gserviceaccount.com']
) }}",
" {{ create_row_access_policy(
    principals = ['serviceAccount:metabase@cal-itp-data-infra.iam.gserviceaccount.com',
                  'serviceAccount:bq-transform-svcacct@cal-itp-data-infra.iam.gserviceaccount.com',
                  'group:cal-itp@jarv.us',
                  'domain:calitp.org',
                  'user:angela@compiler.la',
                  'user:easall@gmail.com',
                  'user:jeremyscottowades@gmail.com',
                 ]
) }}",
]

) }}
-- TODO: In the last policy of the macro call above, see if we can get the prod warehouse service account out of context

WITH

fct_daily_schedule_feeds AS (
    SELECT * FROM {{ ref('fct_daily_schedule_feeds') }}
),

dim_routes AS (
    SELECT * FROM {{ ref('dim_routes') }}
),

dim_gtfs_datasets AS (
    SELECT * FROM {{ ref('dim_gtfs_datasets') }}
),

payments_feeds AS (
    SELECT * FROM {{ ref('payments_feeds') }}
),

stg_cleaned_micropayments AS (
    SELECT *
    FROM {{ ref('stg_cleaned_micropayments') }}
),

stg_cleaned_micropayment_device_transactions AS (
    SELECT *
    FROM {{ ref('stg_cleaned_micropayment_device_transactions') }}
),

stg_cleaned_micropayment_adjustments AS (
    SELECT *
    FROM {{ ref('stg_cleaned_micropayment_adjustments') }}
),

stg_cleaned_device_transactions AS (
    SELECT *
    FROM {{ ref('stg_cleaned_device_transactions') }}
),

stg_cleaned_device_transaction_types AS (
    SELECT *
    FROM {{ ref('stg_cleaned_device_transaction_types') }}
),

stg_cleaned_customers AS (
    SELECT *
    FROM {{ ref('stg_cleaned_customers') }}
),

stg_cleaned_customer_funding_source_vaults AS (
    SELECT *
    FROM {{ ref('stg_cleaned_customer_funding_source_vaults') }}
),

stg_cleaned_product_data AS (
    SELECT *
    FROM {{ ref('stg_cleaned_product_data') }}
),

participants_to_routes AS (
    SELECT
        pf.participant_id,
        f.date,
        r.route_id,
        r.route_short_name,
        r.route_long_name,
    FROM payments_feeds AS pf
    LEFT JOIN dim_gtfs_datasets d
        ON pf.gtfs_dataset_source_record_id = d.source_record_id
    LEFT JOIN fct_daily_schedule_feeds AS f
        ON d.key = f.gtfs_dataset_key
    LEFT JOIN dim_routes AS r
        ON f.feed_key = r.feed_key
),

debited_micropayments AS (
    SELECT *
    FROM stg_cleaned_micropayments
    WHERE type = 'DEBIT'
),

refunded_micropayments AS (
    SELECT

        m_debit.micropayment_id,
        m_credit.charge_amount AS refund_amount

    FROM debited_micropayments AS m_debit
    INNER JOIN stg_cleaned_micropayment_device_transactions AS mds
        ON m_debit.micropayment_id = mds.micropayment_id
    INNER JOIN stg_cleaned_micropayment_device_transactions AS dt_credit
        ON mds.littlepay_transaction_id = dt_credit.littlepay_transaction_id
    INNER JOIN stg_cleaned_micropayments AS m_credit
        ON dt_credit.micropayment_id = m_credit.micropayment_id
    WHERE m_credit.type = 'CREDIT'
        AND m_credit.charge_type = 'refund'
),

applied_adjustments AS (
    SELECT

        participant_id,
        micropayment_id,
        product_id,
        adjustment_id,
        type,
        time_period_type,
        description,
        amount

    FROM stg_cleaned_micropayment_adjustments
    WHERE applied IS True
),

initial_transactions AS (
    SELECT
        mdt.*,

        dt.participant_id,
        dt.customer_id,
        dt.device_transaction_id,
        dt.device_id,
        dt.device_id_issuer,
        dt.type,
        dt.transaction_outcome,
        dt.transction_deny_reason,
        dt.transaction_date_time_utc,
        dt.location_scheme,
        dt.location_name,
        dt.zone_id,
        dt.mode,
        dt.direction,
        dt.vehicle_id,
        dt.granted_zone_ids,
        dt.onward_zone_ids,
        dt.latitude,
        dt.longitude,
        dt.transaction_date_time_pacific,
        dt.route_id,
        dt.location_id,
        dt.geography,

        dtt.transaction_type,
        dtt.pending

    FROM stg_cleaned_micropayment_device_transactions AS mdt
    INNER JOIN stg_cleaned_device_transactions AS dt
        ON mdt.littlepay_transaction_id = dt.littlepay_transaction_id
    INNER JOIN stg_cleaned_device_transaction_types AS dtt
        ON mdt.littlepay_transaction_id = dtt.littlepay_transaction_id
    WHERE dtt.transaction_type IN ('single', 'on')
),

second_transactions AS (
    SELECT
        mdt.*,

        dt.participant_id,
        dt.customer_id,
        dt.device_transaction_id,
        dt.device_id,
        dt.device_id_issuer,
        dt.type,
        dt.transaction_outcome,
        dt.transction_deny_reason,
        dt.transaction_date_time_utc,
        dt.location_scheme,
        dt.location_name,
        dt.zone_id,
        dt.mode,
        dt.direction,
        dt.vehicle_id,
        dt.granted_zone_ids,
        dt.onward_zone_ids,
        dt.latitude,
        dt.longitude,
        dt.transaction_date_time_pacific,
        dt.route_id,
        dt.location_id,
        dt.geography,

        dtt.transaction_type,
        dtt.pending

    FROM stg_cleaned_micropayment_device_transactions AS mdt
    INNER JOIN stg_cleaned_device_transactions AS dt
        ON mdt.littlepay_transaction_id = dt.littlepay_transaction_id
    INNER JOIN stg_cleaned_device_transaction_types AS dtt
        ON mdt.littlepay_transaction_id = dtt.littlepay_transaction_id
    WHERE dtt.transaction_type = 'off'
),

join_table AS (
    SELECT

        m.participant_id,
        m.micropayment_id,

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
        mr.refund_amount,
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
        r.route_long_name,
        r.route_short_name,
        t1.direction,
        t1.vehicle_id,
        t1.littlepay_transaction_id,

        -- Tap on or single transaction info
        t1.device_id,
        t1.transaction_type,
        t1.transaction_outcome,
        t1.transaction_date_time_utc,
        t1.transaction_date_time_pacific,
        t1.location_id,
        t1.location_name,
        t1.latitude,

        -- should we remove latitute and longitude in favor
        -- of on_latitude and on_longitude
        t1.longitude,
        t1.latitude AS on_latitude,
        t1.longitude AS on_longitude,
        t1.geography AS on_geography,
        t2.littlepay_transaction_id AS off_littlepay_transaction_id,

        -- Tap off transaction info
        t2.device_id AS off_device_id,
        t2.transaction_type AS off_transaction_type,
        t2.transaction_outcome AS off_transaction_outcome,
        t2.transaction_date_time_utc AS off_transaction_date_time_utc,
        t2.transaction_date_time_pacific AS off_transaction_date_time_pacific,
        t2.location_id AS off_location_id,
        t2.location_name AS off_location_name,
        t2.latitude AS off_latitude,
        t2.longitude AS off_longitude,
        t2.geography AS off_geography,
        COALESCE(t1.route_id, t2.route_id) AS route_id

    FROM debited_micropayments AS m
    LEFT JOIN refunded_micropayments AS mr
        ON m.micropayment_id = mr.micropayment_id
    INNER JOIN stg_cleaned_customers AS c
        ON m.customer_id = c.customer_id
    LEFT JOIN stg_cleaned_customer_funding_source_vaults AS v
        ON m.funding_source_vault_id = v.funding_source_vault_id
            AND m.transaction_time >= v.calitp_valid_at
            AND m.transaction_time < v.calitp_invalid_at
    INNER JOIN initial_transactions AS t1
        ON m.participant_id = t1.participant_id
            AND m.micropayment_id = t1.micropayment_id
    LEFT JOIN second_transactions AS t2
        ON m.participant_id = t2.participant_id
            AND m.micropayment_id = t2.micropayment_id
    LEFT JOIN applied_adjustments AS a
        ON m.participant_id = a.participant_id
            AND m.micropayment_id = a.micropayment_id
    LEFT JOIN stg_cleaned_product_data AS p
        ON m.participant_id = p.participant_id
            AND a.product_id = p.product_id
    LEFT JOIN participants_to_routes AS r
        ON r.participant_id = m.participant_id
            -- here, can just use t1 because transaction date will be populated
            -- (don't have to handle unkowns the way we do with route_id)
            AND EXTRACT(DATE FROM TIMESTAMP(t1.transaction_date_time_utc)) = r.date
            AND r.route_id = COALESCE(t1.route_id, t2.route_id)
),

payments_rides AS (
    SELECT

        *,
        DATETIME_DIFF(
            off_transaction_date_time_pacific,
            transaction_date_time_pacific,
            MINUTE
        ) AS duration,
        ST_DISTANCE(on_geography, off_geography) AS distance_meters,
        CAST(transaction_date_time_pacific AS date) AS transaction_date_pacific,
        EXTRACT(DAYOFWEEK FROM transaction_date_time_pacific) AS day_of_week

    FROM join_table
)

SELECT * FROM payments_rides

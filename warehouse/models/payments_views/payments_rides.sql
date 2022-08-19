{{ config(
    post_hook=[" {{ create_row_access_policy(
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
) }}"
]

) }}

WITH

gtfs_routes_with_participant AS (
    SELECT

        participant_id,
        route_id,
        route_short_name,
        route_long_name,
        calitp_extracted_at,
        calitp_deleted_at

    FROM {{ ref('gtfs_schedule_dim_routes') }}
    INNER JOIN {{ ref('payments_feeds') }} USING (calitp_itp_id, calitp_url_number)
),

debited_micropayments AS (
    SELECT *
    FROM {{ ref('stg_cleaned_micropayments') }}
    WHERE type = 'DEBIT'
),

refunded_micropayments AS (
    SELECT

        m_debit.micropayment_id,
        m_credit.charge_amount AS refund_amount

    FROM debited_micropayments AS m_debit
    INNER JOIN {{ ref('stg_cleaned_micropayment_device_transactions') }} USING (micropayment_id)
    INNER JOIN {{ ref('stg_cleaned_micropayment_device_transactions') }} AS dt_credit USING (littlepay_transaction_id)
    INNER JOIN {{ ref('stg_cleaned_micropayments') }} AS m_credit ON
        dt_credit.micropayment_id = m_credit.micropayment_id
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

    FROM {{ ref('stg_cleaned_micropayment_adjustments') }}
    WHERE applied IS True
),

initial_transactions AS (
    SELECT *
    FROM {{ ref('stg_cleaned_micropayment_device_transactions') }}
    INNER JOIN {{ ref('stg_cleaned_device_transactions') }} USING (littlepay_transaction_id)
    INNER JOIN {{ ref('stg_cleaned_device_transaction_types') }} USING (littlepay_transaction_id)
    WHERE transaction_type IN ('single', 'on')
),

second_transactions AS (
    SELECT *
    FROM {{ ref('stg_cleaned_micropayment_device_transactions') }}
    INNER JOIN {{ ref('stg_cleaned_device_transactions') }} USING (littlepay_transaction_id)
    INNER JOIN {{ ref('stg_cleaned_device_transaction_types') }} USING (littlepay_transaction_id)
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
    CASE WHEN t1.route_id != 'Route Z' THEN t1.route_id ELSE COALESCE(t2.route_id, 'Route Z') END AS route_id,
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

FROM debited_micropayments AS m
LEFT JOIN refunded_micropayments AS mr USING (micropayment_id)
INNER JOIN {{ ref('stg_cleaned_customers') }} AS c USING (customer_id)
LEFT JOIN {{ ref('stg_cleaned_customer_funding_source_vaults') }} AS v
    ON m.funding_source_vault_id = v.funding_source_vault_id
        AND m.transaction_time >= v.calitp_valid_at
        AND m.transaction_time < v.calitp_invalid_at
INNER JOIN initial_transactions AS t1 USING (participant_id, micropayment_id)
LEFT JOIN second_transactions AS t2 USING (participant_id, micropayment_id)
LEFT JOIN applied_adjustments AS a USING (participant_id, micropayment_id)
LEFT JOIN {{ ref('stg_cleaned_product_data') }} AS p USING (participant_id, product_id)
LEFT JOIN gtfs_routes_with_participant AS r
    ON r.participant_id = m.participant_id
        AND r.route_id = (CASE WHEN t1.route_id != 'Route Z' THEN t1.route_id ELSE COALESCE(t2.route_id, 'Route Z') END)
        -- here, can just use t1 because transaction date will be populated
        -- (don't have to handle unkowns the way we do with route_id)
        AND r.calitp_extracted_at <= DATETIME(TIMESTAMP(t1.transaction_date_time_utc))
        AND r.calitp_deleted_at > DATETIME(TIMESTAMP(t1.transaction_date_time_utc))

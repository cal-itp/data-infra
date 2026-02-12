{{ config(materialized = 'table',
    post_hook="{{ payments_enghouse_row_access_policy() }}") }}

WITH transactions AS (
    SELECT * FROM {{ ref('stg_enghouse__transactions') }}
),

taps AS (
    SELECT * FROM {{ ref('stg_enghouse__taps') }}
),

payments_entity_mapping AS (
    SELECT
        * EXCEPT(enghouse_operator_id),
        enghouse_operator_id AS operator_id
    FROM {{ ref('payments_entity_mapping_enghouse') }}
),

fct_daily_schedule_feeds AS (
    SELECT * FROM {{ ref('fct_daily_schedule_feeds') }}
),

dim_gtfs_datasets AS (
    SELECT * FROM {{ ref('dim_gtfs_datasets') }}
),

dim_orgs AS (
    SELECT * FROM {{ ref('dim_organizations') }}
),

dim_agency AS (
    SELECT * FROM {{ ref('dim_agency') }}
),

dim_routes AS (
    SELECT * FROM {{ ref('dim_routes') }}
),

participants_to_routes_and_agency AS (
    SELECT
        map.operator_id,
        map.organization_source_record_id,
        map._in_use_from,
        map._in_use_until,
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

join_orgs AS (
    SELECT
        transactions.*,

        dim_orgs.name AS organization_name,
        dim_orgs.source_record_id AS organization_source_record_id,

        -- Common transaction info
        routes.route_long_name,
        routes.route_short_name,
        routes.agency_id,
        routes.agency_name
    FROM transactions
    LEFT JOIN taps
        ON transactions.payment_reference = taps.payment_reference
    LEFT JOIN participants_to_routes_and_agency AS routes
        ON transactions.operator_id = routes.operator_id
            AND EXTRACT(DATE FROM TIMESTAMP(transactions.timestamp)) = routes.date
            AND routes.route_id = taps.line_public_number
            AND CAST(transactions.timestamp AS TIMESTAMP)
                BETWEEN CAST(routes._in_use_from AS TIMESTAMP)
                AND CAST(routes._in_use_until AS TIMESTAMP)
    LEFT JOIN dim_orgs
        ON routes.organization_source_record_id = dim_orgs.source_record_id
        AND CAST(transactions.timestamp AS TIMESTAMP) BETWEEN dim_orgs._valid_from AND dim_orgs._valid_to
),

fct_payments_settlements AS (
    SELECT
        organization_name,
        organization_source_record_id,
        operator_id,
        id,
        operation,
        terminal_id,
        mapping_terminal_id,
        mapping_merchant_id,
        timestamp,
        amount,
        payment_reference,
        spdh_response,
        response_type,
        response_message,
        token,
        issuer_response,
        core_response,
        rrn,
        authorization_code,
        par,
        brand,
        route_long_name,
        route_short_name,
        agency_id,
        agency_name,
        LAST_DAY(EXTRACT(DATE FROM timestamp AT TIME ZONE "America/Los_Angeles"), MONTH) AS end_of_month_date_pacific,
        LAST_DAY(EXTRACT(DATE FROM timestamp), MONTH) AS end_of_month_date_utc,
        _content_hash
    FROM join_orgs
)

SELECT * FROM fct_payments_settlements

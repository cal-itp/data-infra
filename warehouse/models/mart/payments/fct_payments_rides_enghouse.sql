{{ config(materialized = 'table',
    post_hook="{{ payments_enghouse_row_access_policy() }}") }}

WITH ticket_results AS (
    SELECT * FROM {{ ref('stg_enghouse__ticket_results') }}
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

fct_payments_rides_enghouse AS (
    SELECT

        ticket_results.operator_id,
        ticket_results.id,
        ticket_results.ticket_id,
        ticket_results.station_name,
        ticket_results.amount,
        ticket_results.clearing_id,
        ticket_results.reason,
        ticket_results.tap_id,
        ticket_results.ticket_type,
        ticket_results.created_dttm,
        ticket_results.line,
        ticket_results.start_station,
        ticket_results.end_station,
        ticket_results.start_dttm,
        ticket_results.end_dttm,
        ticket_results.ticket_code,
        ticket_results.additional_infos,

        taps.mapping_terminal_id,
        taps.mapping_merchant_id,
        taps.terminal,
        taps.token,
        taps.masked_pan,
        taps.expiry,
        taps.server_date,
        taps.terminal_date,
        taps.tx_number,
        taps.tx_status,
        taps.payment_reference,
        taps.terminal_spdh_code,
        taps.denylist_version,
        taps.currency,
        taps.par,
        taps.fare_mode,
        taps.fare_type,
        taps.fare_value,
        taps.fare_description,
        taps.fare_linked_id,
        taps.gps_longitude,
        taps.gps_latitude,
        taps.gps_altitude,
        taps.vehicle_public_number,
        taps.vehicle_name,
        taps.stop_id,
        taps.stop_name,
        taps.platform_id,
        taps.platform_name,
        taps.zone_id,
        taps.zone_name,
        taps.line_public_number,
        taps.line_name,
        taps.line_direction,
        taps.trip_public_number,
        taps.trip_name,
        taps.service_public_number,
        taps.service_name,
        taps.driver_id,

        -- Common transaction info
        routes.route_long_name,
        routes.route_short_name,
        routes.agency_id,
        routes.agency_name

    FROM ticket_results
    LEFT JOIN taps
        ON ticket_results.tap_id = taps.tap_id
    LEFT JOIN participants_to_routes_and_agency AS routes
        ON routes.operator_id = ticket_results.operator_id
            AND EXTRACT(DATE FROM TIMESTAMP(ticket_results.start_dttm)) = routes.date
            AND routes.route_id = taps.line_public_number
            AND CAST(ticket_results.start_dttm AS TIMESTAMP)
                BETWEEN CAST(routes._in_use_from AS TIMESTAMP)
                AND CAST(routes._in_use_until AS TIMESTAMP)
    LEFT JOIN dim_orgs
        ON routes.organization_source_record_id = dim_orgs.source_record_id
        AND CAST(transactions.timestamp AS TIMESTAMP) BETWEEN dim_orgs._valid_from AND dim_orgs._valid_to

)

SELECT * FROM fct_payments_rides_enghouse

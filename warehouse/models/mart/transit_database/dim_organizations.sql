{{ config(materialized='table') }}

WITH stg_transit_database__organizations AS (
    SELECT * FROM {{ ref('stg_transit_database__organizations') }}
),

organizations_scd AS (
    SELECT
        {{ dbt_utils.surrogate_key(['record_id', 'ts']) }} AS key,
        record_id,
        name,
        organization_type,
        roles,
        itp_id,
        details,
        caltrans_district,
        website,
        reporting_category,
        ntp_id,
        gtfs_static_status,
        gtfs_realtime_status,
        alias,
        ts AS _valid_from,
        LEAD({{ make_end_of_valid_range('ts') }}, 1, CAST("2099-01-01" AS TIMESTAMP)) OVER (PARTITION BY record_id ORDER BY ts) AS _valid_to
    FROM stg_transit_database__organizations
),

dim_organizations AS (
    SELECT *, _valid_to = CAST("2099-01-01" AS TIMESTAMP) AS is_latest
    FROM organizations_scd
)

SELECT * FROM dim_organizations

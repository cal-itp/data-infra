{{ config(materialized='table') }}

WITH
latest AS (
    {{ get_latest_external_data(
        external_table = source('airtable', 'california_transit__services'),
        order_by = 'dt DESC, time DESC'
        ) }}
),

stg_transit_database__services AS (
    SELECT
        service_id AS key,
        name,
        service_type,
        mode,
        currently_operating,
        paratransit_for,
        provider,
        operator,
        dt AS calitp_extracted_at
    FROM latest
)

SELECT * FROM stg_transit_database__services

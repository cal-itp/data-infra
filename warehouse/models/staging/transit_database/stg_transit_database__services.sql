{{ config(materialized='table') }}

WITH
latest AS (
    {{ get_latest_external_data(
        external_table_name = source('airtable', 'california_transit__services'),
        columns = 'dt DESC, time DESC'
        ) }}
),

stg_transit_database__services AS (
    SELECT
        service_id AS id,
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

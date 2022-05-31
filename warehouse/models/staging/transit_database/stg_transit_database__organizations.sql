{{ config(materialized='table') }}

WITH
latest AS (
    {{ get_latest_external_data(
        external_table_name = source('airtable', 'california_transit__organizations'),
        columns = 'dt DESC, time DESC'
        ) }}
),

stg_transit_database__organizations AS (
    SELECT * EXCEPT(name),
        name as organization_name
    FROM latest
)

SELECT * FROM stg_transit_database__organizations

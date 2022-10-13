{{ config(materialized='table') }}

WITH stg_transit_database__components AS (
    SELECT * FROM {{ ref('stg_transit_database__components') }}
),

components_scd AS (
    SELECT
        {{ dbt_utils.surrogate_key(['record_id', 'ts']) }} AS key,
        record_id,
        name,
        aliases,
        description,
        function_group,
        system,
        location,
        ts AS _valid_from,
        LEAD({{ make_end_of_valid_range('ts') }}, 1, CAST("2099-01-01" AS TIMESTAMP)) OVER (PARTITION BY record_id ORDER BY ts) AS _valid_to
    FROM stg_transit_database__components
),

dim_components AS (
    SELECT *, _valid_to = CAST("2099-01-01" AS TIMESTAMP) AS is_latest
    FROM components_scd
)

SELECT * FROM dim_components

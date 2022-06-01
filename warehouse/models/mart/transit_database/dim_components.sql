{{ config(materialized='table') }}

WITH stg_transit_database__components AS (
    SELECT * FROM {{ ref('stg_transit_database__components') }}
),

components AS (
    SELECT
        component_id,
        component_name,
        aliases,
        description,
        function_group,
        system,
        location,
        calitp_extracted_at
    FROM stg_transit_database__components
)

SELECT * FROM components

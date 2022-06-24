{{ config(materialized='table') }}

WITH
latest AS (
    {{ get_latest_external_data(
        external_table = source('airtable', 'california_transit__rider_requirements'),
        order_by = 'dt DESC, time DESC'
        ) }}
),

stg_transit_database__rider_requirements AS (
    SELECT
        rider_requirement_id AS key,
        {{ trim_make_empty_string_null(column_name = "requirement") }},
        category,
        description,
        services,
        unnested_eligibility_programs AS eligibility_programs,
        time,
        dt AS calitp_extracted_at
    FROM latest
    LEFT JOIN UNNEST(latest.eligibility_programs) AS unnested_eligibility_programs
)

SELECT * FROM stg_transit_database__rider_requirements

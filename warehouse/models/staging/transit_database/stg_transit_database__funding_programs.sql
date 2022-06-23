{{ config(materialized='table') }}

WITH
latest AS (
    {{ get_latest_external_data(
        external_table = source('airtable', 'california_transit__funding_programs'),
        order_by = 'dt DESC, time DESC'
        ) }}
),

stg_transit_database__funding_programs AS (
    SELECT
        funding_program_id AS key,
        {{ trim_make_empty_string_null(column_name = "program") }},
        full_name,
        program_informatiom,
        services,
        organization,
        category,
        drmt_data,
        time,
        dt AS calitp_extracted_at
    FROM latest
)

SELECT * FROM stg_transit_database__funding_programs

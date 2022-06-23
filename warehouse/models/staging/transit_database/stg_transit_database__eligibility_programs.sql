{{ config(materialized='table') }}

WITH
latest AS (
    {{ get_latest_external_data(
        external_table = source('airtable', 'california_transit__eligibility_programs'),
        order_by = 'dt DESC, time DESC'
        ) }}
),

stg_transit_database__eligibility_programs AS (
    SELECT
        eligibility_program_id AS key,
        {{ trim_make_empty_string_null(column_name = "program") }},
        administering_entity,
        eligibility_types,
        services,
        process,
        assumed_eligibility__appointment_,
        appointment_duration__hours_,
        expected_process_turn_around_application_eligibility__days_,
        website,
        time,
        dt AS calitp_extracted_at
    FROM latest
)

SELECT * FROM stg_transit_database__eligibility_programs

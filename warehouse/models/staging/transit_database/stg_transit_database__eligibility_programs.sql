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
        id AS key,
        {{ trim_make_empty_string_null(column_name = "program") }},
        unnested_administering_entity AS administering_entity_organization_key,
        unnested_eligibility_types AS eligibility_type_rider_requirement_key,
        unnested_services AS service_key,
        process,
        assumed_eligibility__appointment_,
        appointment_duration__hours_,
        expected_process_turn_around_application_eligibility__days_,
        website,
        time,
        dt AS calitp_extracted_at
    FROM latest
    LEFT JOIN UNNEST(latest.administering_entity) AS unnested_administering_entity
    LEFT JOIN UNNEST(latest.eligibility_types) AS unnested_eligibility_types
    LEFT JOIN UNNEST(latest.services) AS unnested_services
)

SELECT * FROM stg_transit_database__eligibility_programs

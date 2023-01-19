WITH

once_daily_eligibility_programs AS (
    {{ get_latest_dense_rank(
        external_table = source('airtable', 'california_transit__eligibility_programs'),
        order_by = 'ts DESC', partition_by = 'dt'
        ) }}
),

stg_transit_database__eligibility_programs AS (
    SELECT
        id,
        {{ trim_make_empty_string_null(column_name = "program") }} AS program,
        unnested_administering_entity AS administering_entity_organization_key,
        unnested_eligibility_types AS eligibility_type_rider_requirement_key,
        unnested_services AS service_key,
        process,
        assumed_eligibility__appointment_,
        appointment_duration__hours_,
        expected_process_turn_around_application_eligibility__days_,
        website,
        dt
    FROM once_daily_eligibility_programs
    LEFT JOIN UNNEST(once_daily_eligibility_programs.administering_entity) AS unnested_administering_entity
    LEFT JOIN UNNEST(once_daily_eligibility_programs.eligibility_types) AS unnested_eligibility_types
    LEFT JOIN UNNEST(once_daily_eligibility_programs.services) AS unnested_services
)

SELECT * FROM stg_transit_database__eligibility_programs

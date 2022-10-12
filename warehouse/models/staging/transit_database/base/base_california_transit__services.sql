WITH

source AS (
    SELECT * FROM {{ source('airtable_ct', 'california_transit__services') }}
),

base_california_transit__services AS (
    SELECT
        id AS key,
        {{ trim_make_empty_string_null(column_name = "name") }} AS name,
        service_type,
        fare_systems,
        mode,
        currently_operating,
        paratransit_for,
        provider,
        operator,
        funding_sources,
        -- TODO: remove this field when v2, automatic determinations are available
        gtfs_schedule_status
        -- TODO: remove this field when v2, automatic determinations are available
        gtfs_schedule_quality,
        operating_counties,
        ts
    FROM source
    QUALIFY ROW_NUMBER() OVER (PARTITION BY name, ts ORDER BY null) = 1
)

SELECT * FROM base_california_transit__services

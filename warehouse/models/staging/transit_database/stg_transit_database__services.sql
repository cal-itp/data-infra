WITH

once_daily_services AS (
    {{ get_latest_dense_rank(
        external_table = source('airtable', 'california_transit__services'),
        order_by = 'ts DESC', partition_by = 'dt'
        ) }}
),

stg_transit_database__services AS (
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
        gtfs_schedule_status,
        -- TODO: remove this field when v2, automatic determinations are available
        gtfs_schedule_quality,
        operating_counties,
        assessment_status,
        dt AS calitp_extracted_at
    FROM once_daily_services
)

SELECT * FROM stg_transit_database__services

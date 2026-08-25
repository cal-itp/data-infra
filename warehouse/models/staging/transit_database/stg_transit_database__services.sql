WITH

once_daily_services AS (
    {{ get_latest_dense_rank(
        external_table = source('airtable', 'california_transit__services'),
        order_by = 'ts DESC', partition_by = 'dt'
        ) }}
),

stg_transit_database__services AS (
    SELECT
        id,
        {{ trim_make_empty_string_null(column_name = "name") }} AS name,
        service_type,
        fare_systems,
        mode,
        currently_operating,
        fixed_route,
        is_public,
        public_currently_operating = "Yes" AS public_currently_operating,
        public_currently_operating_fixed_route = "Yes" AS public_currently_operating_fixed_route,
        public_conditional_currently_operating = "Yes" AS public_conditional_currently_operating,
        start_date,
        operational_status,
        -- demand response and paratransit fields
        paratransit_for,
        complementary_paratransit_service,
        rider_requirements,
        {{ trim_make_empty_string_null(column_name = "reservation_methods") }} AS reservation_methods,
        {{ trim_make_empty_string_null(column_name = "booking_lead_time") }} AS booking_lead_time,
        {{ trim_make_empty_string_null(column_name = "paratransit_exemption_notes") }} AS paratransit_exemption_notes,
        provider,
        operator,
        funding_sources,
        gtfs_schedule_status, -- TODO: remove this field when v2, automatic determinations are available
        gtfs_schedule_quality, -- TODO: remove this field when v2, automatic determinations are available
        operating_counties,
        assessment_status,
        manual_check__gtfs_realtime_data_ingested_in_trip_planner,
        manual_check__gtfs_schedule_data_ingested_in_trip_planner,
        primary_mode,
        deprecated_date,
        operating_county_geographies,
        dt
    FROM once_daily_services
)

SELECT * FROM stg_transit_database__services

{{
    config(
        materialized='table',
        tags=['tides_reference'],
    )
}}

-- Organization <-> GTFS feed crosswalk for the published TIDES dataset: every
-- version of every dim_provider_gtfs_data record belonging to an organization
-- that appears in the TIDES facts.
-- Links an `organization_source_record_id` observed in vehicle_locations /
-- trips_performed to the organization's schedule / vehicle-positions /
-- trip-updates / service-alerts feeds, valid for a given service date:
--     _valid_from <= service_date < _valid_to

WITH tides_provider_gtfs_data AS (
    SELECT
        key,
        organization_source_record_id,
        organization_name,
        organization_ntd_id,
        service_source_record_id,
        service_name,
        gtfs_service_data_customer_facing,
        regional_feed_type,
        public_customer_facing_fixed_route,
        public_customer_facing_or_regional_subfeed_fixed_route,
        schedule_source_record_id,
        schedule_gtfs_dataset_name,
        schedule_gtfs_dataset_key,
        service_alerts_source_record_id,
        service_alerts_gtfs_dataset_name,
        service_alerts_gtfs_dataset_key,
        vehicle_positions_source_record_id,
        vehicle_positions_gtfs_dataset_name,
        vehicle_positions_gtfs_dataset_key,
        trip_updates_source_record_id,
        trip_updates_gtfs_dataset_name,
        trip_updates_gtfs_dataset_key,
        _valid_from,
        _valid_to,
        _is_current
    FROM {{ ref('dim_provider_gtfs_data') }}
    WHERE organization_source_record_id IN (
        SELECT organization_source_record_id
        FROM {{ ref('tides_publication_organizations') }}
    )
)

SELECT * FROM tides_provider_gtfs_data

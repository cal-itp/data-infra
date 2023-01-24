{{ config(materialized='table') }}

WITH datasets AS (
    SELECT *
    FROM {{ ref('dim_gtfs_datasets') }}
),

int_gtfs_quality__daily_assessment_candidate_entities AS (
    -- select distinct to drop duplicate gtfs service data records
    -- which sometimes exist
    SELECT DISTINCT
        date,
        organization_key,
        organization_name,
        organization_itp_id,
        organization_hubspot_company_record_id,
        organization_ntd_id,
        organization_source_record_id,
        service_key,
        service_name,
        service_source_record_id,
        gtfs_dataset_key,
        gtfs_dataset_name,
        gtfs_dataset_type,
        gtfs_service_data_customer_facing,
        regional_feed_type,
        agency_id,
        route_id,
        network_id,
        CASE
            WHEN gtfs_dataset_type = "schedule" THEN gtfs_dataset_key
            WHEN gtfs_dataset_type IS NOT NULL THEN schedule_to_use_for_rt_validation_gtfs_dataset_key
        END as associated_schedule_gtfs_dataset_key
    FROM {{ ref('int_gtfs_quality__daily_assessment_candidate_entities') }}
),

-- handle cases where there are multiple RT feeds with identical relationships
-- (same org, service, associated schedule, customer_facing, etc.)
-- also handle cases where there are feeds with missing relationships
disambiguate_dups AS (
    SELECT
        date,
        organization_key,
        organization_name,
        organization_itp_id,
        organization_hubspot_company_record_id,
        organization_ntd_id,
        organization_source_record_id,
        service_key,
        service_name,
        service_source_record_id,
        gtfs_dataset_key,
        gtfs_dataset_type,
        gtfs_service_data_customer_facing,
        regional_feed_type,
        agency_id,
        route_id,
        network_id,
        associated_schedule_gtfs_dataset_key,
                ROW_NUMBER() OVER (
            PARTITION BY
                date,
                organization_key,
                service_key,
                gtfs_dataset_type,
                gtfs_service_data_customer_facing,
                regional_feed_type,
                agency_id,
                route_id,
                network_id,
                associated_schedule_gtfs_dataset_key
            -- try to get some name that will group like feeds together
            ORDER BY
                REGEXP_REPLACE(
                    gtfs_dataset_name,
                    '(Trip Updates|TripUpdates|Alerts|Vehicle Positions|VehiclePositions|Schedule)',
                    '')
        ) AS ordered
    FROM int_gtfs_quality__daily_assessment_candidate_entities
),

pivoted AS (
    SELECT
        *,
        {{ dbt_utils.surrogate_key([
            'organization_key',
            'service_key',
            'associated_schedule_gtfs_dataset_key',
            'gtfs_dataset_key_schedule',
            'gtfs_dataset_key_service_alerts',
            'gtfs_dataset_key_trip_updates',
            'gtfs_dataset_key_vehicle_positions',
            'gtfs_service_data_customer_facing',
            'regional_feed_type']) }} AS key,
        MAX(date) OVER(PARTITION BY {{ dbt_utils.surrogate_key([
            'organization_key',
            'service_key',
            'associated_schedule_gtfs_dataset_key',
            'gtfs_dataset_key_schedule',
            'gtfs_dataset_key_service_alerts',
            'gtfs_dataset_key_trip_updates',
            'gtfs_dataset_key_vehicle_positions',
            'gtfs_service_data_customer_facing',
            'regional_feed_type']) }} ORDER BY date DESC) AS latest_extract
    FROM disambiguate_dups
    PIVOT(
        STRING_AGG(gtfs_dataset_key) AS gtfs_dataset_key
        FOR gtfs_dataset_type IN ('schedule', 'service_alerts', 'trip_updates', 'vehicle_positions')
    )
),

next_valid_extract AS (
    SELECT
        date,
        LEAD(date) OVER (ORDER BY date) AS next_dt
    FROM pivoted
    GROUP BY date
),

-- following: https://dba.stackexchange.com/questions/210907/determine-consecutive-occurrences-of-values
first_instances AS (
    SELECT
        pivoted.date,
        key,
        latest_extract,
        (DENSE_RANK() OVER (ORDER BY latest_extract DESC)) = 1 AS in_latest,
        next_dt,
        (RANK() OVER  (PARTITION BY key ORDER BY pivoted.date)) = 1 AS is_first
    FROM pivoted
    LEFT JOIN next_valid_extract AS next
        ON pivoted.latest_extract = next.date
    QUALIFY is_first
),

all_versioned AS (
    SELECT
        key,
        date AS _valid_from,
        -- if there's no subsequent extract, it was either deleted or it's current
        -- if it was in the latest extract, call it current (even if it errored)
        -- if it was not in the latest extract, call it deleted at the last time it was extracted
        CASE
            WHEN in_latest THEN {{ make_end_of_valid_range('CAST("2099-01-01" AS TIMESTAMP)') }}
            ELSE {{ make_end_of_valid_range('CAST(next_dt AS TIMESTAMP)') }}
        END AS _valid_to
    FROM first_instances
),

dim_provider_gtfs_data AS (
    SELECT
        {{ dbt_utils.surrogate_key([
            'organization_key',
            'service_key',
            'associated_schedule_gtfs_dataset_key',
            'gtfs_dataset_key_schedule',
            'gtfs_dataset_key_service_alerts',
            'gtfs_dataset_key_vehicle_positions',
            'gtfs_dataset_key_trip_updates',
            'gtfs_service_data_customer_facing'
            ]) }} AS key,
        organization_key,
        organization_name,
        organization_itp_id,
        organization_hubspot_company_record_id,
        organization_ntd_id,
        organization_source_record_id,
        service_key,
        service_name,
        service_source_record_id,
        gtfs_service_data_customer_facing,
        orig.regional_feed_type,
        associated_schedule_gtfs_dataset_key,
        sched.name AS schedule_gtfs_dataset_name,
        sched.source_record_id AS schedule_source_record_id,
        alerts.name AS service_alerts_gtfs_dataset_name,
        alerts.source_record_id AS service_alerts_source_record_id,
        vehicle_positions.name AS vehicle_positions_gtfs_dataset_name,
        vehicle_positions.source_record_id AS vehicle_positions_source_record_id,
        trip_updates.name AS trip_updates_gtfs_dataset_name,
        trip_updates.source_record_id AS trip_updates_source_record_id,
        gtfs_dataset_key_schedule AS schedule_gtfs_dataset_key,
        gtfs_dataset_key_service_alerts AS service_alerts_gtfs_dataset_key,
        gtfs_dataset_key_vehicle_positions AS vehicle_positions_gtfs_dataset_key,
        gtfs_dataset_key_trip_updates AS trip_updates_gtfs_dataset_key,
        CAST(all_versioned._valid_from AS TIMESTAMP) AS _valid_from,
        all_versioned._valid_to,
        all_versioned._valid_to = {{ make_end_of_valid_range('CAST("2099-01-01" AS TIMESTAMP)') }} AS _is_current
    FROM all_versioned
    LEFT JOIN pivoted AS orig
        ON all_versioned.key = orig.key
        AND all_versioned._valid_from = orig.date
    LEFT JOIN datasets AS sched
        ON orig.gtfs_dataset_key_schedule = sched.key
    LEFT JOIN datasets AS alerts
        ON orig.gtfs_dataset_key_service_alerts = alerts.key
    LEFT JOIN datasets AS trip_updates
        ON orig.gtfs_dataset_key_trip_updates = trip_updates.key
    LEFT JOIN datasets AS vehicle_positions
        ON orig.gtfs_dataset_key_vehicle_positions = vehicle_positions.key
)

SELECT * FROM dim_provider_gtfs_data

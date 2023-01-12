{{ config(materialized='table') }}

WITH int_gtfs_quality__daily_assessment_candidate_entities AS (
    SELECT
        date,
        organization_key,
        service_key,
        gtfs_dataset_key,
        gtfs_dataset_type,
        gtfs_service_data_customer_facing,
        regional_feed_type,
        CASE
            WHEN gtfs_dataset_type = "schedule" THEN gtfs_dataset_key
            WHEN gtfs_dataset_type IS NOT NULL THEN schedule_to_use_for_rt_validation_gtfs_dataset_key
        END as associated_gtfs_schedule_key
    FROM {{ ref('int_gtfs_quality__daily_assessment_candidate_entities') }}
),

pivoted AS (
    SELECT
        *,
        {{ dbt_utils.surrogate_key([
            'organization_key',
            'service_key',
            'associated_gtfs_schedule_key',
            'gtfs_dataset_key_schedule',
            'gtfs_dataset_key_service_alerts',
            'gtfs_dataset_key_trip_updates',
            'gtfs_dataset_key_vehicle_positions',
            'gtfs_service_data_customer_facing',
            'regional_feed_type']) }} AS key,
        MAX(date) OVER(PARTITION BY {{ dbt_utils.surrogate_key([
            'organization_key',
            'service_key',
            'associated_gtfs_schedule_key',
            'gtfs_dataset_key_schedule',
            'gtfs_dataset_key_service_alerts',
            'gtfs_dataset_key_trip_updates',
            'gtfs_dataset_key_vehicle_positions',
            'gtfs_service_data_customer_facing',
            'regional_feed_type']) }} ORDER BY date DESC) AS latest_extract
    FROM int_gtfs_quality__daily_assessment_candidate_entities
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

final AS (
    SELECT
        all_versioned.* EXCEPT(key, _valid_from),
        CAST(_valid_from AS TIMESTAMP) AS _valid_from,
        orig.* EXCEPT(date),
        _valid_to = {{ make_end_of_valid_range('CAST("2099-01-01" AS TIMESTAMP)') }} AS _is_current
    FROM all_versioned
    LEFT JOIN pivoted AS orig
        ON all_versioned._valid_from = orig.date
        AND all_versioned.key = orig.key

)

SELECT * FROM final

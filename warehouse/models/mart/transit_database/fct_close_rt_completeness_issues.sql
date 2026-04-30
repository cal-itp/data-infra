{{ config(materialized='table') }}

WITH filtered_issues AS (
    SELECT
        source_record_id AS issue_source_record_id,
        gtfs_dataset_source_record_id,
        gtfs_dataset_name,
        issue_type_name,
        outreach_status,
        service_name,
        issue__ AS issue_number
    FROM {{ ref('fct_transit_data_quality_issues') }}
    WHERE is_open = TRUE
      AND issue_type_name = 'GTFS Realtime Completeness Problem'
),

rt_completeness_by_feed AS (
    SELECT
        st.name,
        dp.vehicle_positions_source_record_id,
        dp.trip_updates_source_record_id,

        ROUND(
            100 * SAFE_DIVIDE(
                SUM(CASE WHEN ot.tu_num_distinct_message_ids > 0 THEN 1 ELSE 0 END),
                COUNT(*)
            ),
            2
        ) AS percentage_of_trips_with_tu_messages,

        ROUND(
            100 * SAFE_DIVIDE(
                SUM(CASE WHEN ot.vp_num_distinct_message_ids > 0 THEN 1 ELSE 0 END),
                COUNT(*)
            ),
            2
        ) AS percentage_of_trips_with_vp_messages
    FROM {{ ref('fct_scheduled_trips') }} st
    LEFT JOIN {{ ref('fct_observed_trips') }} ot
        ON st.trip_instance_key = ot.trip_instance_key
    LEFT JOIN {{ ref('dim_provider_gtfs_data') }} dp
        ON st.gtfs_dataset_key = dp.schedule_gtfs_dataset_key
       AND st.service_date BETWEEN DATE(dp._valid_from) AND DATE(dp._valid_to)
    WHERE st.service_date BETWEEN DATE_ADD(CURRENT_DATE('America/Los_Angeles'), INTERVAL -14 DAY)
                              AND DATE_ADD(CURRENT_DATE('America/Los_Angeles'), INTERVAL -1 DAY)
    GROUP BY
        st.name,
        dp.vehicle_positions_source_record_id,
        dp.trip_updates_source_record_id
),

filtered_issues_with_completeness AS (
    SELECT
        fi.* EXCEPT (gtfs_dataset_source_record_id),

        COALESCE(
            vp_feed.percentage_of_trips_with_vp_messages,
            tu_feed.percentage_of_trips_with_vp_messages,
            0
        ) AS percentage_of_trips_with_vp_messages,

        COALESCE(
            vp_feed.percentage_of_trips_with_tu_messages,
            tu_feed.percentage_of_trips_with_tu_messages,
            0
        ) AS percentage_of_trips_with_tu_messages,

        COALESCE(
            vp_feed.percentage_of_trips_with_vp_messages,
            tu_feed.percentage_of_trips_with_tu_messages,
            0
        ) AS rt_completeness_percentage

    FROM filtered_issues fi
    LEFT JOIN rt_completeness_by_feed vp_feed
        ON fi.gtfs_dataset_source_record_id = vp_feed.vehicle_positions_source_record_id
    LEFT JOIN rt_completeness_by_feed tu_feed
        ON fi.gtfs_dataset_source_record_id = tu_feed.trip_updates_source_record_id
),

fct_close_rt_completeness_issues AS (
    SELECT *
    FROM filtered_issues_with_completeness
    WHERE percentage_of_trips_with_tu_messages >= 80
      AND percentage_of_trips_with_vp_messages >= 80
)

SELECT *
FROM fct_close_rt_completeness_issues

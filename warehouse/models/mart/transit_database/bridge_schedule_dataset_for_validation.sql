{{ config(materialized='table') }}

WITH datasets AS ( -- noqa
    SELECT *
    FROM {{ ref('int_transit_database__gtfs_datasets_dim') }}
),

bridge_schedule_dataset_for_validation AS (
    SELECT
        datasets.key AS gtfs_dataset_key,
        datasets.name AS gtfs_dataset_name,
        sched_ref.key AS schedule_to_use_for_rt_validation_gtfs_dataset_key,
        sched_ref.name AS schedule_to_use_for_rt_validation_gtfs_dataset_name,
        (datasets._is_current AND sched_ref._is_current) AS _is_current,
        GREATEST(datasets._valid_from, sched_ref._valid_from) AS _valid_from,
        LEAST(datasets._valid_to, sched_ref._valid_to) AS _valid_to
    FROM datasets
    LEFT JOIN datasets AS sched_ref
        ON datasets.schedule_to_use_for_rt_validation_gtfs_dataset_key = sched_ref.original_record_id
        AND datasets._valid_from < sched_ref._valid_to
        AND datasets._valid_to > sched_ref._valid_from
)

SELECT * FROM bridge_schedule_dataset_for_validation

{{ config(materialized='table') }}

WITH

unioned AS (
    {{ dbt_utils.union_relations(
        relations=[
            ref('int_gtfs_quality__shapes_accurate'),
            ref('int_gtfs_quality__data_license'),
            ref('int_gtfs_quality__authentication_acceptable'),
            ref('int_gtfs_quality__stable_url'),
            ref('int_gtfs_quality__grading_scheme_v1'),
        ],
    ) }}
),

fct_daily_gtfs_dataset_guideline_checks AS (
    SELECT
        {{ dbt_utils.surrogate_key(['date', 'gtfs_dataset_key', 'check']) }} AS key,
        *
    FROM unioned
)

SELECT * FROM fct_daily_gtfs_dataset_guideline_checks

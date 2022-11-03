WITH

fct_daily_guideline_checks AS (
    {{ dbt_utils.union_relations(
        relations=[
            ref('int_gtfs_guidelines_v2__no_schedule_validation_errors'),
        ],
    ) }}
)

SELECT * FROM fct_daily_guideline_checks

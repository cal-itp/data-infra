{{ config(materialized='table') }}

WITH

unioned AS (
    {{ dbt_utils.union_relations(
        relations=[
            ref('int_gtfs_quality__contact_on_website'),
        ],
    ) }}
),

fct_daily_organization_guideline_checks AS (
    SELECT
        {{ dbt_utils.surrogate_key(['date', 'organization_key', 'check']) }} AS key,
        *
    FROM unioned
)

SELECT * FROM fct_daily_organization_guideline_checks

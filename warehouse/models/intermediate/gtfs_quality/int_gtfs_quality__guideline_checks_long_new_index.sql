-- TODO: this will replace int_gtfs_quality__guideline_checks once ready
-- description for this table got too long, don't persist to BQ
{{ config(materialized='table', persist_docs={"relation": false, "columns": true}) }}


WITH unioned AS (
    -- TODO: this is not migrated yet, this is just the first intended check to migrate
    {{ dbt_utils.union_relations(
        relations=[
            ref('int_gtfs_quality__schedule_download_success'),
        ],
    ) }}
),

int_gtfs_quality__guideline_checks_long_new_index AS (
    SELECT *
    FROM unioned
)

SELECT * FROM int_gtfs_quality__guideline_checks_long_new_index

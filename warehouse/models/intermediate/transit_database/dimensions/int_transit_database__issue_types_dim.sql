{{ config(materialized='table') }}

WITH latest_data_schemas AS (
    {{ get_latest_dense_rank(
        external_table = ref('stg_transit_database__issue_types'),
        order_by = 'dt DESC'
        ) }}
),

historical AS (
    SELECT
        *,
        TRUE AS _is_current,
        CAST(universal_first_val AS TIMESTAMP) AS _valid_from,
        {{ make_end_of_valid_range('CAST("2099-01-01" AS TIMESTAMP)') }} AS _valid_to
    FROM latest_data_schemas
),

unnested AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['id', '_valid_from']) }} AS key,
        id,
        dataset_type,
        transit_data_quality_issue,
        name,
        notes,
        _is_current,
        _valid_from,
        _valid_to,
    FROM historical,
    UNNEST(transit_data_quality_issues) as transit_data_quality_issue
),

int_transit_database__issue_types AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['id', '_valid_from', 'transit_data_quality_issue']) }} AS key,
        id AS source_record_id,
        dataset_type,
        transit_data_quality_issue,
        name,
        notes,
        _is_current,
        _valid_from,
        _valid_to,
    FROM unnested
)

SELECT * FROM int_transit_database__issue_types

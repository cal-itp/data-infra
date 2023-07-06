{{ config(materialized='table') }}

WITH latest_data_schemas AS (
    {{ get_latest_dense_rank(
        external_table = ref('stg_transit_data_quality_issues__issue_types'),
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

int_transit_data_quality_issues__issue_types AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['id', '_valid_from']) }} AS key,
        id AS source_record_id,
        dataset_type,
        transit_data_quality_issues,
        name,
        notes,
        _is_current,
        _valid_from,
        _valid_to,
    FROM historical
)

SELECT * FROM int_transit_data_quality_issues__issue_types

{{ config(materialized='table') }}

WITH int_transit_database__issue_types AS (
    SELECT * FROM {{ ref('int_transit_database__issue_types') }}
),

dim_transit_data_quality_issue_types AS (
    SELECT
        key,
        source_record_id,
        dataset_type,
        transit_data_quality_issues,
        name,
        notes,
        _is_current,
        _valid_from,
        _valid_to,
    FROM int_transit_database__issue_types
)

SELECT * FROM dim_transit_data_quality_issue_types

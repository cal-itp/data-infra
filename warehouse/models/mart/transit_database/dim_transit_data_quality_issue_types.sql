{{ config(materialized='table') }}

WITH int_transit_database__issue_types_dim AS (
    SELECT * FROM {{ ref('int_transit_database__issue_types_dim') }}
),

dim_transit_data_quality_issue_types AS (
    SELECT
        key,
        source_record_id,
        dataset_type,
        transit_data_quality_issue,
        name,
        notes,
        _is_current,
        _valid_from,
        _valid_to,
    FROM int_transit_database__issue_types_dim
)

SELECT * FROM dim_transit_data_quality_issue_types

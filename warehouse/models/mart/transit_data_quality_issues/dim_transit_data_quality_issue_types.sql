{{ config(materialized='table') }}

WITH stg_transit_data_quality_issues__issue_types AS (
    SELECT * FROM {{ ref('stg_transit_data_quality_issues__issue_types') }}
),

dim_transit_data_quality_issue_types AS (
    SELECT
        id,
        dataset_type,
        transit_data_quality_issues,
        name,
        notes,
    FROM stg_transit_data_quality_issues__issue_types
)

SELECT * FROM dim_transit_data_quality_issue_types

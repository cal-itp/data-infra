WITH
once_daily_issue_types AS (
    {{ get_latest_dense_rank(
        external_table = source('airtable', 'transit_data_quality_issues__issue_types'),
        order_by = 'ts DESC', partition_by = 'dt'
        ) }}
),

stg_transit_database__issue_types AS (
    SELECT
        id,
        dataset_type,
        transit_data_quality_issues,
        name,
        notes,
        dt,
        ts,
    FROM once_daily_issue_types
)

SELECT * FROM stg_transit_database__issue_types

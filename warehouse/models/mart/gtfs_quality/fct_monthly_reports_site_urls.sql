{{ config(materialized='table') }}

WITH reports_index AS (
    SELECT *
    FROM {{ ref('idx_monthly_reports_site') }}
    --WHERE publish_date > '2022-11-30' -- test
),

dataset_map AS (
    SELECT *
    FROM {{ ref('int_gtfs_quality__organization_dataset_map') }}
    WHERE reports_site_assessed
),

urls_all_month AS (
    SELECT DISTINCT
        idx.publish_date, --idx.date_start, idx.date_end,
        idx.organization_itp_id, idx.organization_name, idx.organization_source_record_id,
        map.gtfs_dataset_name, map.base64_url
    FROM reports_index AS idx
    INNER JOIN dataset_map as map
    ON idx.organization_source_record_id = map.organization_source_record_id
        AND map.date BETWEEN idx.date_start AND idx.date_end
    ORDER BY idx.publish_date
)

SELECT * FROM urls_all_month

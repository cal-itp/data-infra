WITH dim_stops AS (
    SELECT  * FROM {{ ref('dim_stops') }}
),

date_org_index AS (
    SELECT DISTINCT * FROM {{ ref('idx_monthly_reports_site') }}
),

organization_dataset_map AS (
    SELECT * FROM {{ ref('int_gtfs_quality__organization_dataset_map') }}
),

month_start AS (
    SELECT
        orgs.base64_url,
        orgs.schedule_feed_key AS feed_key,
        orgs.organization_name,
        dim_stops.stop_id,
        index.publish_date
    FROM date_org_index AS index
    LEFT JOIN organization_dataset_map AS orgs ON (index.date_start = orgs.date)
        AND (index.organization_name = orgs.organization_name)
    INNER JOIN dim_stops ON (orgs.schedule_feed_key = dim_stops.feed_key)
),

month_end AS (
    SELECT
        orgs.base64_url,
        orgs.schedule_feed_key AS feed_key,
        orgs.organization_name,
        dim_stops.stop_id,
        index.publish_date
    FROM date_org_index AS index
    LEFT JOIN organization_dataset_map AS orgs ON  (index.date_end = orgs.date)
        AND (index.organization_name = orgs.organization_name)
    INNER JOIN dim_stops ON (orgs.schedule_feed_key = dim_stops.feed_key)

),

month_comparison AS (
    SELECT
        * EXCEPT (stop_id),
        t1.stop_id AS start_table_source_id,
        t2.stop_id AS stop_table_source_id,
        CASE
            WHEN t2.stop_id IS NULL AND t1.stop_id IS NOT NULL THEN 'Removed'
            WHEN t1.stop_id IS NULL AND t2.stop_id IS NOT NULL THEN 'Added'
            ELSE 'Unchanged'
        END AS change_status
    FROM month_start AS t1
    FULL JOIN month_end AS t2
              USING (organization_name, stop_id, publish_date)

),

fct_monthly_stop_id_changes AS (

    SELECT
        organization_name,
        publish_date,
        change_status,
        COUNT(*) AS n
    FROM month_comparison GROUP BY 1, 2, 3

)

SELECT * FROM fct_monthly_stop_id_changes

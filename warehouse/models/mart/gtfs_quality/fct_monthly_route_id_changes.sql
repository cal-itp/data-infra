WITH dim_routes AS (
    SELECT  * FROM {{ ref('dim_routes') }}
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
        dim_routes.route_id,
        index.publish_date
    FROM date_org_index AS index
    LEFT JOIN organization_dataset_map AS orgs ON (index.date_start = orgs.date)
        AND (index.organization_name = orgs.organization_name)
    INNER JOIN dim_routes ON (orgs.schedule_feed_key = dim_routes.feed_key)
),

month_end AS (
    SELECT
        orgs.base64_url,
        orgs.schedule_feed_key AS feed_key,
        orgs.organization_name,
        dim_routes.route_id,
        index.publish_date
    FROM date_org_index AS index
    LEFT JOIN organization_dataset_map AS orgs ON  (index.date_end = orgs.date)
        AND (index.organization_name = orgs.organization_name)
    INNER JOIN dim_routes ON (orgs.schedule_feed_key = dim_routes.feed_key)

),

month_comparison AS (
    SELECT
        * EXCEPT (route_id),
        t1.route_id AS start_table_source_id,
        t2.route_id AS stop_table_source_id,
        CASE
            WHEN t2.route_id IS NULL AND t1.route_id IS NOT NULL THEN 'Removed'
            WHEN t1.route_id IS NULL AND t2.route_id IS NOT NULL THEN 'Added'
            ELSE 'Unchanged'
        END AS change_status
    FROM month_start AS t1
    FULL JOIN month_end AS t2
              USING (organization_name, route_id, publish_date)

),

fct_monthly_route_id_changes AS (

    SELECT
        organization_name,
        publish_date,
        change_status,
        COUNT(*) AS n
    FROM month_comparison GROUP BY 1, 2, 3

)

SELECT * FROM fct_monthly_route_id_changes

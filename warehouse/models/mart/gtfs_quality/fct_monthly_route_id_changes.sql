WITH reports_index AS (
    SELECT * FROM {{ ref('idx_monthly_reports_site') }}
),

organization_dataset_map AS (
    SELECT * FROM {{ ref('int_gtfs_quality__organization_dataset_map') }}
),

dim_routes AS (
    SELECT  * FROM {{ ref('dim_routes') }}
),

month_start AS (
    SELECT

        reports_index.organization_name,
        reports_index.organization_itp_id,
        reports_index.publish_date,

        orgs.base64_url,
        orgs.schedule_feed_key AS feed_key,

        dim_routes.route_id

    FROM reports_index
    LEFT JOIN organization_dataset_map AS orgs ON (reports_index.date_start = orgs.date)
        AND (reports_index.organization_source_record_id = orgs.organization_source_record_id)
        --AND (reports_index.organization_name = orgs.organization_name)
        --AND (reports_index.organization_itp_id = orgs.organization_itp_id)

    INNER JOIN dim_routes ON (orgs.schedule_feed_key = dim_routes.feed_key)
),

month_end AS (
    SELECT

        reports_index.organization_name,
        reports_index.organization_itp_id,
        reports_index.publish_date,

        orgs.base64_url,
        orgs.schedule_feed_key AS feed_key,

        dim_routes.route_id

    FROM reports_index
    LEFT JOIN organization_dataset_map AS orgs ON (reports_index.date_end = orgs.date)
        AND (reports_index.organization_source_record_id = orgs.organization_source_record_id)
        --AND (reports_index.organization_name = orgs.organization_name)
        --AND (reports_index.organization_itp_id = orgs.organization_itp_id)

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
            USING (base64_url, organization_name, organization_itp_id, route_id, publish_date)
            --USING (organization_name, organization_itp_id, route_id, publish_date)

),

fct_monthly_route_id_changes AS (

    SELECT
        organization_name,
        organization_itp_id,
        publish_date,
        change_status,
        COUNT(*) AS n
    FROM month_comparison GROUP BY 1, 2, 3, 4

)

SELECT * FROM fct_monthly_route_id_changes

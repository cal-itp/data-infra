WITH reports_index AS (
    SELECT * FROM {{ ref('idx_monthly_reports_site') }}
),

organization_dataset_map AS (
    SELECT * FROM {{ ref('int_gtfs_quality__organization_dataset_map') }}
    WHERE public_customer_facing_or_regional_subfeed_fixed_route
),

dim_routes AS (
    SELECT  * FROM {{ ref('dim_routes') }}
),

month_start AS (
    SELECT

        reports_index.organization_name,
        reports_index.organization_itp_id,
        reports_index.publish_date,
        reports_index.organization_source_record_id,

        orgs.base64_url,
        orgs.schedule_feed_key AS feed_key,

        dim_routes.route_id

    FROM reports_index
    LEFT JOIN organization_dataset_map AS orgs ON (reports_index.date_start = orgs.date)
        AND (reports_index.organization_source_record_id = orgs.organization_source_record_id)
    INNER JOIN dim_routes ON (orgs.schedule_feed_key = dim_routes.feed_key)
        WHERE dim_routes.route_id IS NOT NULL
),

month_end AS (
    SELECT

        reports_index.organization_name,
        reports_index.organization_itp_id,
        reports_index.publish_date,
        reports_index.organization_source_record_id,

        orgs.base64_url,
        orgs.schedule_feed_key AS feed_key,

        dim_routes.route_id

    FROM reports_index
    LEFT JOIN organization_dataset_map AS orgs ON (reports_index.date_end = orgs.date)
        AND (reports_index.organization_source_record_id = orgs.organization_source_record_id)
    INNER JOIN dim_routes ON (orgs.schedule_feed_key = dim_routes.feed_key)
        WHERE dim_routes.route_id IS NOT NULL
),

month_comparison AS (
    SELECT

        COALESCE(month_start.organization_name, month_end.organization_name) AS organization_name,
        COALESCE(month_start.organization_itp_id, month_end.organization_itp_id) AS organization_itp_id,
        COALESCE(month_start.organization_source_record_id, month_end.organization_source_record_id) AS organization_source_record_id,
        COALESCE(month_start.publish_date, month_end.publish_date) AS publish_date,

        month_start.route_id AS start_table_source_id,
        month_end.route_id AS stop_table_source_id,

        CASE
            WHEN month_end.route_id IS NULL THEN 'Removed'
            WHEN month_start.route_id IS NULL THEN 'Added'
            ELSE 'Unchanged'
        END AS change_status

    FROM month_start
    FULL JOIN month_end
            USING (organization_source_record_id, route_id, publish_date)
),

fct_monthly_route_id_changes AS (

    SELECT
        organization_name,
        organization_itp_id,
        organization_source_record_id,
        publish_date,
        change_status,
        COUNT(*) AS n
    FROM month_comparison GROUP BY 1, 2, 3, 4, 5

)

SELECT * FROM fct_monthly_route_id_changes

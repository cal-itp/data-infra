WITH dim_stops AS (
    SELECT  * FROM {{ ref('dim_stops') }}
),

feed_version_history AS (
    SELECT * FROM {{ ref('int_gtfs_quality__feed_version_history') }}
),

stop_id_comparison AS (
    SELECT * FROM {{ ids_version_compare_aggregate("stop_id","dim_stops") }}
),

date_range AS (
    SELECT DISTINCT date_start, date_end, publish_date FROM {{ ref('idx_monthly_reports_site') }}
),

month_start AS (
    SELECT
        base64_url,
        feed_key,
        id,
        publish_date
    FROM stop_id_comparison
    INNER JOIN date_range ON valid_from <= date_start
        AND next_feed_valid_from > date_start
),

month_end AS (
    SELECT
        base64_url,
        feed_key,
        id,
        publish_date
    FROM stop_id_comparison
    INNER JOIN date_range ON valid_from <= date_end
        AND next_feed_valid_from > date_end

),

month_comparison AS (
    SELECT
        * EXCEPT (id),
        t1.id AS start_table_source_id,
        t2.id AS stop_table_source_id,
        CASE
            WHEN t2.id IS NULL AND t1.id IS NOT NULL THEN 'Removed'
            WHEN t1.id IS NULL AND t2.id IS NOT NULL THEN 'Added'
            ELSE 'Unchanged'
        END AS change_status
    FROM month_start AS t1
    FULL JOIN month_end AS t2
              USING (base64_url, feed_key, id, publish_date)

),

fct_monthly_stop_id_changes AS (

    SELECT
        base64_url,
        feed_key,
        publish_date,
        change_status,
        COUNT(*) AS n
    FROM month_comparison GROUP BY 1, 2, 3, 4

)

SELECT * FROM fct_monthly_stop_id_changes

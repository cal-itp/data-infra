WITH dim_stops AS (
    SELECT  * FROM {{ ref('dim_stops') }}
),

feed_version_history AS (
    SELECT * FROM {{ ref('int_gtfs_quality__feed_version_history') }}
),

stop_id_comparison AS (
    SELECT * FROM {{ ids_version_compare_aggregate("stop_id","dim_stops") }}
),

fct_monthly_stop_id_changes AS (
    SELECT * FROM stop_id_comparison
)

SELECT * FROM fct_monthly_stop_id_changes

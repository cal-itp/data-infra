WITH dim_routes AS (
    SELECT  * FROM {{ ref('dim_routes') }}
),

feed_version_history AS (
    SELECT * FROM {{ ref('int_gtfs_quality__feed_version_history') }}
),

route_id_comparison AS (
    SELECT * FROM {{ ids_version_compare_aggregate("route_id","dim_routes") }}
),

fct_monthly_route_id_changes AS (
    SELECT * FROM route_id_comparison
)

SELECT * FROM fct_monthly_route_id_changes

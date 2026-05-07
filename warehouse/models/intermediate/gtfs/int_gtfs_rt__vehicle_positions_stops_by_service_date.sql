{{
    config(
        materialized='incremental',
        incremental_strategy = 'insert_overwrite',
        partition_by={
            'field': 'service_date',
            'data_type': 'date',
            'granularity': 'day'
        }, cluster_by=['service_date', 'vp_base64_url', 'feed_key']
    )
}}

-- depends_on: {{ ref('dim_schedule_feeds') }}
-- add dependency hint to let dbt know about the dependency inside the call statement block

-- fetch a list of _feed_valid_from dates that are implicated in these updates
-- **the where clause here needs to align exactly with the where clause used on fct_scheduled_trips below**
-- this allows us to filter stop times grouped for significant efficiency gains
-- https://stackoverflow.com/questions/64007239/how-do-we-define-select-statement-as-a-variable-in-dbt
{% call statement('get_dates', fetch_result=True) %}
    SELECT ARRAY_TO_STRING(ARRAY_AGG(DISTINCT '"' || feeds._valid_from || '"' ), ',')
    FROM {{ ref('fct_scheduled_trips') }} AS trips
    LEFT JOIN {{ ref('dim_schedule_feeds') }} AS feeds
    ON trips.feed_key = feeds.key
    WHERE service_date
        BETWEEN {{ ranged_incremental_min_date(default_lookback=var("DBT_ALL_INCREMENTAL_LOOKBACK_DAYS"), data_earliest_start=var("GTFS_RT_STOP_ANALYSIS_START")) }}
            AND {{ ranged_incremental_max_date() }}
{% endcall %}

{% set date_list = load_result('get_dates')['data'][0][0] %}

WITH trips AS (
    SELECT
        feed_key,
        service_date,
        trip_id,
        trip_instance_key,
        trip_first_departure_sec,
    FROM {{ ref('fct_scheduled_trips') }}
    WHERE service_date
        BETWEEN {{ ranged_incremental_min_date(default_lookback=var("DBT_ALL_INCREMENTAL_LOOKBACK_DAYS"), data_earliest_start=var("GTFS_RT_STOP_ANALYSIS_START")) }}
            AND {{ ranged_incremental_max_date() }}
),

stop_times_grouped AS (
    SELECT
        key, -- from feed_key, trip_id, trip_first_departure_sec
        feed_key,
        trip_id,
        trip_first_departure_sec,
        stop_id_array,

    FROM {{ ref('int_gtfs_schedule__stop_times_grouped') }}
    -- use the list of feed keys fetched above
    -- note that you can't use a subquery here because BQ doesn't do partition elimination on subqueries
    WHERE _feed_valid_from in ({{ date_list }})
),

stops AS (
    SELECT
        feed_key,
        service_date,
        stop_id,
        pt_geom,

    FROM {{ ref('fct_daily_scheduled_stops') }}
    WHERE service_date
        BETWEEN {{ ranged_incremental_min_date(default_lookback=var("DBT_ALL_INCREMENTAL_LOOKBACK_DAYS"), data_earliest_start=var("GTFS_RT_STOP_ANALYSIS_START")) }}
            AND {{ ranged_incremental_max_date() }}
),

daily_rt_feeds AS (
    SELECT DISTINCT
        schedule_feed_key,
        base64_url AS vp_base64_url,
    FROM {{ ref('fct_daily_rt_feed_files') }}
    WHERE `date`
        -- add one to the incremental max date because we need to get one extra UTC dt to ensure overlap with service date
        BETWEEN {{ ranged_incremental_min_date(default_lookback=var("DBT_ALL_INCREMENTAL_LOOKBACK_DAYS"), data_earliest_start=var("GTFS_RT_STOP_ANALYSIS_START")) }}
            AND {{ ranged_incremental_max_date() }} + 1
        AND feed_type = 'vehicle_positions'
),

vehicle_locations AS (
    SELECT
        key,
        service_date,
        base64_url,
        trip_instance_key,
        location
    FROM {{ ref('fct_vehicle_locations') }}
    -- we load this by dt rather than service date
    -- this is ok for the min date because t-X days for service date will be fully covered by t-X days for dt
    -- add one to the incremental max date because we need to get one extra UTC dt to ensure overlap with service date
    WHERE dt
        BETWEEN {{ ranged_incremental_min_date(default_lookback=var("DBT_ALL_INCREMENTAL_LOOKBACK_DAYS"), data_earliest_start=var("GTFS_RT_STOP_ANALYSIS_START")) }}
            AND {{ ranged_incremental_max_date() }} + 1
),

schedule_joins AS (
    SELECT
        trips.feed_key,
        trips.service_date,
        trips.trip_instance_key,
        stop_times_grouped.key AS st_trip_key,
        stop_id,
        stops.pt_geom,
    -- what we want is the batch of all scheduled trips from the last X service dates
    FROM trips
    LEFT JOIN stop_times_grouped
        ON trips.feed_key = stop_times_grouped.feed_key
        AND trips.trip_id = stop_times_grouped.trip_id
        AND trips.trip_first_departure_sec = stop_times_grouped.trip_first_departure_sec
    -- use trip_first_departure_sec instead of iteration_num because scheduled_trips does more coalescing on iteration_num, so we might not match it
    LEFT JOIN UNNEST(stop_times_grouped.stop_id_array) AS stop_id
    LEFT JOIN stops
        ON trips.feed_key = stops.feed_key
        AND trips.service_date = stops.service_date
        AND stop_id = stops.stop_id
    -- TODO: add a where filter if needed to filter out rows missing any critical info
),

-- we only want scheduled trips that have a VP url associated
-- this could potentially be split out into a dedicated upstream model
-- so that the filtering on grouped stop times could be even tighter
scheduled_with_vp_url AS (
    SELECT
        schedule_joins.feed_key,
        schedule_joins.service_date,
        schedule_joins.trip_instance_key,
        schedule_joins.st_trip_key,
        schedule_joins.stop_id,
        schedule_joins.pt_geom,
        daily_rt_feeds.vp_base64_url
    FROM schedule_joins
    INNER JOIN daily_rt_feeds
        ON schedule_joins.feed_key = daily_rt_feeds.schedule_feed_key
),


vp_near_stops AS (
   SELECT
        scheduled_with_vp_url.service_date,
        scheduled_with_vp_url.vp_base64_url,
        vehicle_locations.key AS vp_key,
        --vehicle_locations.location,

        scheduled_with_vp_url.feed_key,
        scheduled_with_vp_url.trip_instance_key,
        scheduled_with_vp_url.stop_id,
        scheduled_with_vp_url.st_trip_key, -- use to key back into schedule trip info found in stop times (int_gtfs_schedule__stop_times_grouped)
        --schedule_joins.pt_geom,

        MIN(ROUND(ST_DISTANCE(vehicle_locations.location, scheduled_with_vp_url.pt_geom), 2)) AS distance_meters,
        --ST_CLOSESTPOINT(vehicle_locations.location, schedule_joins.pt_geom) is returning a point useful? It'll be difficult to match against, use vp_keys instead and distances

    FROM scheduled_with_vp_url
    -- we only want trips with data so inner join is ok
    -- TODO, though, for testing: try a left join and confirm that trips only get dropped because they don't have locations data and not because of date mismatches
    INNER JOIN vehicle_locations
        ON scheduled_with_vp_url.vp_base64_url = vehicle_locations.base64_url
        AND scheduled_with_vp_url.service_date = vehicle_locations.service_date
        AND scheduled_with_vp_url.trip_instance_key = vehicle_locations.trip_instance_key
        AND ST_DWITHIN(vehicle_locations.location, scheduled_with_vp_url.pt_geom, 100)
        -- 100 meters ~ 0.1 miles, 328 ft
    GROUP BY service_date, vp_base64_url, feed_key, trip_instance_key, stop_id, st_trip_key, vp_key
),

int_gtfs_rt__vehicle_positions_stops_by_service_date AS (
    SELECT
        service_date,
        vp_base64_url,
        feed_key,
        trip_instance_key,
        stop_id,
        st_trip_key,

        COUNTIF(distance_meters <= 100) AS near_100m,
        COUNTIF(distance_meters <= 50) AS near_50m,
        COUNTIF(distance_meters <= 25) AS near_25m,
        COUNTIF(distance_meters <= 10) AS near_10m,
        ARRAY_AGG(distance_meters ORDER BY distance_meters, vp_key) AS distance_meters_array,
        ARRAY_AGG(vp_key ORDER BY distance_meters, vp_key) AS vp_key_array,

    FROM vp_near_stops
    GROUP BY service_date, vp_base64_url, feed_key, trip_instance_key, stop_id, st_trip_key
)

SELECT * FROM int_gtfs_rt__vehicle_positions_stops_by_service_date

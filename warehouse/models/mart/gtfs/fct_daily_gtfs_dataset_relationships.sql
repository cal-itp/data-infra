{{ config(materialized='table') }}

WITH date_spine AS (
    SELECT *
    FROM {{ ref('util_gtfs_schedule_v2_date_spine') }}
),

dim_provider_gtfs_data AS (
    SELECT *
    FROM {{ ref('dim_provider_gtfs_data') }}
),

int_gtfs_schedule__joined_feed_outcomes AS (
    SELECT *
    FROM {{ ref('int_gtfs_schedule__joined_feed_outcomes') }}
),

fct_daily_schedule_feeds AS (
    SELECT *
    FROM {{ ref('fct_daily_schedule_feeds') }}
),

int_gtfs_rt__daily_url_index AS (
    SELECT *
    FROM {{ ref('int_gtfs_rt__daily_url_index') }}
),

int_transit_database__urls_to_gtfs_datasets AS (
    SELECT *
    FROM {{ ref('int_transit_database__urls_to_gtfs_datasets') }}
),

rt_gtfs_datasets AS (
    SELECT *
    FROM int_gtfs_rt__daily_url_index
    LEFT JOIN int_transit_database__urls_to_gtfs_datasets
        USING (base64_url)
),

schedule_daily_url_index AS (
    SELECT
        EXTRACT(DATE FROM ts) AS dt,
        gtfs_dataset_key,
        base64_url,
        {{ from_url_safe_base64('base64_url') }} AS string_url
    FROM int_gtfs_schedule__joined_feed_outcomes
),

quartet_cross_join AS (
    SELECT *
    FROM date_spine
    CROSS JOIN dim_provider_gtfs_data
),

schedule_join AS (
    SELECT
        quartet.*,
        sched_urls.base64_url AS schedule_base64_url,
        sched_urls.string_url AS schedule_string_url,
        sched_feeds.feed_key AS schedule_feed_key
    FROM quartet_cross_join AS quartet
    LEFT JOIN schedule_daily_url_index AS sched_urls
        ON quartet.date_day = sched_urls.dt
        AND quartet.schedule_gtfs_dataset_key = sched_urls.gtfs_dataset_key
    LEFT JOIN fct_daily_schedule_feeds AS sched_feeds
        ON quartet.date_day = sched_feeds.date
        AND sched_urls.base64_url = sched_feeds.base64_url
        AND sched_urls.gtfs_dataset_key = sched_feeds.gtfs_dataset_key
),

rt_join AS (
    SELECT
        sched.*,
        {% for rt_type in ['service_alerts', 'vehicle_positions', 'trip_updates'] %}
        {{ rt_type }}.base64_url AS {{ rt_type }}_base64_url,
        {{ rt_type }}.string_url AS {{ rt_type }}_string_url {% if not loop.last %}, {% endif %}
        {% endfor %}
    FROM schedule_join AS sched
    {% for rt_type in ['service_alerts', 'vehicle_positions', 'trip_updates'] %}
    LEFT JOIN rt_gtfs_datasets AS {{ rt_type }}
        ON sched.{{ rt_type }}_gtfs_dataset_key = {{ rt_type }}.gtfs_dataset_key
        AND sched.date_day = {{ rt_type }}.dt
    {% endfor %}
)

SELECT * FROM rt_join

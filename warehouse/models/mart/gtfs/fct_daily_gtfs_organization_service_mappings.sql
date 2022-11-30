{{ config(materialized='table') }}

WITH date_spine AS (
    SELECT *
    FROM {{ ref('util_gtfs_schedule_v2_date_spine') }}
    WHERE date_day <= CURRENT_DATE()
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
    QUALIFY RANK() OVER(PARTITION BY dt, gtfs_dataset_key, base64_url ORDER BY ts DESC) = 1
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
        ON sched.{{ rt_type }}_gtfs_dataset_key = COALESCE({{ rt_type }}.gtfs_dataset_key, "")
        AND sched.date_day = {{ rt_type }}.dt
    {% endfor %}
),

fct_daily_gtfs_organization_service_mappings AS (
    SELECT
        date_day AS date,
        {{ dbt_utils.surrogate_key([
            'date_day',
            'key',
            'schedule_base64_url',
            'schedule_feed_key',
            'service_alerts_base64_url',
            'vehicle_positions_base64_url',
            'trip_updates_base64_url']) }} AS key,
        key AS dim_provider_gtfs_data_key,
        service_key,
        service_name,
        organization_key,
        organization_name,
        itp_id,
        customer_facing,
        schedule_gtfs_dataset_key,
        schedule_name,
        service_alerts_gtfs_dataset_key,
        service_alerts_name,
        vehicle_positions_gtfs_dataset_key,
        vehicle_positions_name,
        trip_updates_gtfs_dataset_key,
        trip_updates_name,
        schedule_base64_url,
        schedule_string_url,
        schedule_feed_key,
        service_alerts_base64_url,
        service_alerts_string_url,
        vehicle_positions_base64_url,
        vehicle_positions_string_url,
        trip_updates_base64_url,
        trip_updates_string_url
    FROM rt_join
)

SELECT * FROM fct_daily_gtfs_organization_service_mappings

{% macro gtfs_rt_messages_keying(raw_messages) %}
WITH
    urls_to_gtfs_datasets AS (
    SELECT * FROM {{ ref('int_transit_database__urls_to_gtfs_datasets') }}
    ),

    dim_gtfs_datasets AS (
        SELECT *
        FROM {{ ref('dim_gtfs_datasets') }}
    ),

    validation_bridge AS (
        SELECT *
        FROM {{ ref('bridge_schedule_dataset_for_validation') }}
    ),

    dim_schedule_feeds AS (
        SELECT *
        FROM {{ ref('dim_schedule_feeds') }}
    )

    -- if we ever backfill v1 RT data, the reliance on _config_extract_ts for joins in this table may become problematic
    SELECT
        urls_to_gtfs_datasets.gtfs_dataset_key AS gtfs_dataset_key,
        rt_datasets.name as name,
        schedule_datasets.key AS schedule_gtfs_dataset_key,
        schedule_datasets.base64_url AS schedule_base64_url,
        schedule_datasets.name AS schedule_name,
        dim_schedule_feeds.key AS schedule_feed_key,
        dim_schedule_feeds.feed_timezone AS schedule_feed_timezone,
        rt.* EXCEPT(_name)
    FROM {{ raw_messages }} AS rt
    LEFT JOIN urls_to_gtfs_datasets
        ON rt.base64_url = urls_to_gtfs_datasets.base64_url
        AND rt._config_extract_ts BETWEEN urls_to_gtfs_datasets._valid_from AND urls_to_gtfs_datasets._valid_to
    LEFT JOIN dim_gtfs_datasets AS rt_datasets
        ON urls_to_gtfs_datasets.gtfs_dataset_key = rt_datasets.key
    LEFT JOIN validation_bridge
        ON rt_datasets.key = validation_bridge.gtfs_dataset_key
        AND rt._config_extract_ts BETWEEN validation_bridge._valid_from AND validation_bridge._valid_to
    -- this would need to be changed if we needed to do joins before September 15, 2022 to go via urls_to_gtfs_datasets
    LEFT JOIN dim_gtfs_datasets AS schedule_datasets
        ON validation_bridge.schedule_to_use_for_rt_validation_gtfs_dataset_key = schedule_datasets.key
        AND rt._config_extract_ts BETWEEN schedule_datasets._valid_from AND schedule_datasets._valid_to
    -- use _extract_ts for this join because now we're looking at the actual data
    -- we want the schedule feed that was in effect when this RT data was actually scraped
    LEFT JOIN dim_schedule_feeds
        ON schedule_datasets.base64_url = dim_schedule_feeds.base64_url
        AND rt._extract_ts BETWEEN dim_schedule_feeds._valid_from AND dim_schedule_feeds._valid_to

    {% endmacro %}

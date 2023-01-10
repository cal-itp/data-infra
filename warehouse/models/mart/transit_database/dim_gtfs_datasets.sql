{{ config(materialized='table') }}

WITH dim AS (
    SELECT *
    FROM {{ ref('int_transit_database__gtfs_datasets_dim') }}
),

dim_gtfs_datasets AS (
    SELECT
        dim.key,
        dim.name,
        dim.type,
        dim.regional_feed_type,
        dim.uri,
        dim.future_uri,
        dim.deprecated_date,
        dim.data_quality_pipeline,
        datasets.key AS schedule_to_use_for_rt_validation_gtfs_dataset_key,
        dim.base64_url,
        (dim._is_current AND datasets._is_current) AS _is_current,
        GREATEST(dim._valid_from, datasets._valid_from) AS _valid_from,
        LEAST(dim._valid_to, datasets._valid_to) AS _valid_to
    FROM dim
    LEFT JOIN dim AS datasets
        ON dim.schedule_to_use_for_rt_validation_gtfs_dataset_key = datasets.original_record_id
        AND dim._valid_from < datasets._valid_to
        AND dim._valid_to > datasets._valid_from
)

SELECT * FROM dim_gtfs_datasets

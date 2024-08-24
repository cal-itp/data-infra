{{ config(materialized='table') }}

WITH dim AS (
    SELECT *
    FROM {{ ref('int_transit_database__gtfs_datasets_dim') }}
),

dim_gtfs_datasets AS (
    SELECT
        key,
        source_record_id,
        name,
        type,
        regional_feed_type,
        COALESCE(
            regional_feed_type,
            FIRST_VALUE(regional_feed_type IGNORE NULLS)
                OVER(
                    PARTITION BY source_record_id
                    ORDER BY _valid_from
                    ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)) AS backdated_regional_feed_type,
        uri,
        future_uri,
        deprecated_date,
        data_quality_pipeline,
        manual_check__link_to_dataset_on_website,
        manual_check__accurate_shapes,
        manual_check__data_license,
        manual_check__authentication_acceptable,
        manual_check__stable_url,
        manual_check__localized_stop_tts,
        manual_check__grading_scheme_v1,
        base64_url,
        private_dataset,
        _is_current,
        _valid_from,
        _valid_to
    FROM dim
)

SELECT * FROM dim_gtfs_datasets

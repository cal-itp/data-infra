WITH

-- TODO: we need to change this logic -- this prevents us from successfully joining with GTFS data
-- if it was downloaded based on an earlier extract in a day with multiple extracts
once_daily_gtfs_datasets AS (
    {{ get_latest_dense_rank(
        external_table = source('airtable', 'california_transit__gtfs_datasets'),
        order_by = 'ts DESC', partition_by = 'dt'
        ) }}
),

-- generally we should have been trimming whitespace
-- on the Airflow/GCS side, so trim it here before encoding
trimmed AS (
    SELECT * EXCEPT (uri, pipeline_url),
        TRIM(uri) AS uri,
        TRIM(pipeline_url) AS pipeline_url
    FROM once_daily_gtfs_datasets
),

construct_base64_url AS (
    SELECT
        *,
        -- TODO: update these after we backfill GTFS data before September 15th
        -- url_to_encode is mostly just for debugging
        CASE
            WHEN ts < CAST("2022-09-15" AS TIMESTAMP)
                THEN
                    CASE
                        -- if there are multiple query parameters, we leave the question mark, remove ampersand
                        -- so example.com/gtfs?auth=key&p2=v2 becomes example.com/gtfs?p2=v2
                        WHEN REGEXP_CONTAINS(uri, r"\?[\w]*\=\{\{[\w\s]*\}\}\&")
                            THEN REGEXP_REPLACE(uri, r"[\w]*\=\{\{[\w\s]*\}\}\&", "")
                        -- if only one query parameter, remove the question mark
                        -- so example.com/gtfs?auth=key becomes example.com/gtfs
                        WHEN REGEXP_CONTAINS(uri, r"\?[\w]*\=\{\{[\w\s]*\}\}$")
                            THEN REGEXP_REPLACE(uri, r"\?[\w]*\=\{\{[\w\s]*\}\}$", "")
                        ELSE uri
                END
            ELSE pipeline_url
        END AS url_to_encode,
        CASE
            WHEN ts < CAST("2022-09-15" AS TIMESTAMP)
                THEN
                    CASE
                        -- if there are multiple query parameters, we leave the question mark, remove ampersand
                        -- so example.com/gtfs?auth=key&p2=v2 becomes example.com/gtfs?p2=v2
                        WHEN REGEXP_CONTAINS(uri, r"\?[\w]*\=\{\{[\w\s]*\}\}\&")
                            THEN {{ to_url_safe_base64('REGEXP_REPLACE(uri, r"[\w]*\=\{\{[\w\s]*\}\}\&","")') }}
                        -- if only one query parameter, remove the question mark
                        -- so example.com/gtfs?auth=key becomes example.com/gtfs
                        WHEN REGEXP_CONTAINS(uri, r"\?[\w]*\=\{\{[\w\s]*\}\}$")
                            THEN {{ to_url_safe_base64('REGEXP_REPLACE(uri, r"\?[\w]*\=\{\{[\w\s]*\}\}$","")') }}
                        ELSE {{ to_url_safe_base64('uri') }}
                    END
            ELSE {{ to_url_safe_base64('pipeline_url') }}
        END AS base64_url
    FROM trimmed
),

stg_transit_database__gtfs_datasets AS (
    SELECT
        id,
        {{ trim_make_empty_string_null(column_name = "name") }} AS name,
        data,
        data_quality_pipeline,
        regional_feed_type,
        fares_v2_status,
        fares_notes,
        pathways_status,
        schedule_comments,
        uri,
        future_uri,
        pipeline_url,
        unnested_aggregated_to AS aggregated_to_gtfs_dataset_key,
        provider_gtfs_capacity,
        notes,
        provider,
        operator,
        gtfs_service_mapping,
        dataset_producers,
        unnested_schedule_to_use_for_rt_validation AS schedule_to_use_for_rt_validation_gtfs_dataset_key,
        dataset_publisher,
        deprecated_date,
        authorization_url_parameter_name,
        url_secret_key_name,
        authorization_header_parameter_name,
        header_secret_key_name,
        url_to_encode,
        manual_check__link_to_dataset_on_website,
        manual_check__accurate_shapes,
        manual_check__data_license,
        manual_check__authentication_acceptable,
        manual_check__stable_url,
        manual_check__localized_stop_tts,
        manual_check__grading_scheme_v1,
        base64_url,
        CASE
            WHEN data = "GTFS Schedule" THEN "schedule"
            WHEN data = "GTFS Alerts" THEN "service_alerts"
            WHEN data = "GTFS VehiclePositions" THEN "vehicle_positions"
            WHEN data = "GTFS TripUpdates" THEN "trip_updates"
        END AS type,
        private_dataset,
        analysis_name,
        ts,
        dt
    FROM construct_base64_url
    LEFT JOIN UNNEST(construct_base64_url.aggregated_to) AS unnested_aggregated_to
    LEFT JOIN UNNEST(construct_base64_url.schedule_to_use_for_rt_validation) AS unnested_schedule_to_use_for_rt_validation
)

SELECT * FROM stg_transit_database__gtfs_datasets

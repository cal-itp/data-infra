

WITH
-- TODO: we need to change this logic -- this prevents us from successfully joining with GTFS data
-- if it was downloaded based on an earlier extract in a day with multiple extracts
once_daily_gtfs_datasets AS (
    {{ get_latest_dense_rank(
        external_table = source('airtable', 'california_transit__gtfs_datasets'),
        order_by = 'ts DESC', partition_by = 'dt'
        ) }}
),

construct_base64_url AS (
    SELECT
        *,
        -- TODO: update these after we backfill GTFS data before September 15th
        -- url_to_encode is mostly just for debugging
        CASE
            WHEN ts < CAST("2022-09-15" AS TIMESTAMP)
                CASE
                    -- if there are multiple query parameters, we leave the question mark, remove ampersand
                    -- so example.com/gtfs?auth=key&p2=v2 becomes example.com/gtfs?p2=v2
                    WHEN REGEXP_CONTAINS(uri, r"\?[\w]*\=\{\{[\w\s]*\}\}\&")
                        THEN REGEXP_REPLACE(uri, r"[\w]*\=\{\{[\w\s]*\}\}\&","")
                    -- if only one query parameter, remove the question mark
                    -- so example.com/gtfs?auth=key becomes example.com/gtfs
                    WHEN REGEXP_CONTAINS(uri, r"\?[\w]*\=\{\{[\w\s]*\}\}$")
                        THEN REGEXP_REPLACE(uri, r"\?[\w]*\=\{\{[\w\s]*\}\}$","")
                    ELSE uri
                END
            ELSE pipeline_url
        END AS url_to_encode,
        CASE
            WHEN ts < CAST("2022-09-15" AS TIMESTAMP)
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
    FROM once_daily_gtfs_datasets
)

stg_transit_database__gtfs_datasets AS (
    SELECT
        id AS airtable_record_id,
        {{ trim_make_empty_string_null(column_name = "name") }},
        data,
        data_quality_pipeline,
        fares_v2_status,
        fares_notes,
        pathways_status,
        schedule_comments,
        uri,
        future_uri,
        pipeline_url,
        api_key,
        unnested_aggregated_to AS aggregated_to_gtfs_dataset_airtable_record_id,
        provider_gtfs_capacity,
        service_type,
        category,
        notes,
        referenced_gtfs__from_gtfs_service_mapping_,
        provider,
        operator,
        provider_reporting_category__from_gtfs_service_mapping_,
        feed_metrics,
        gtfs_service_mapping,
        services,
        dataset_producers,
        unnested_schedule_to_use_for_rt_validation AS schedule_to_use_for_rt_validation_gtfs_dataset_airtable_record_id,
        dataset_publisher,
        itp_activities,
        itp_schedule_todo,
        deprecated_date,
        authorization_url_parameter_name,
        url_secret_key_name,
        authorization_header_parameter_name,
        header_secret_key_name,
        url_to_encode,
        base64_url,
        ts,
        dt AS calitp_extracted_at
    FROM once_daily_gtfs_datasets
    LEFT JOIN UNNEST(once_daily_gtfs_datasets.aggregated_to) AS unnested_aggregated_to
    LEFT JOIN UNNEST(once_daily_gtfs_datasets.schedule_to_use_for_rt_validation) AS unnested_schedule_to_use_for_rt_validation
)

SELECT * FROM stg_transit_database__gtfs_datasets

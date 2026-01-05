{{ config(materialized='table') }}

WITH unioned_outcomes AS (
    {% for file_outcome_table in [
        "agency_txt_parse_outcomes",
        "areas_txt_parse_outcomes",
        "attributions_txt_parse_outcomes",
        "calendar_txt_parse_outcomes",
        "calendar_dates_txt_parse_outcomes",
        "fare_attributes_txt_parse_outcomes",
        "fare_leg_rules_txt_parse_outcomes",
        "fare_products_txt_parse_outcomes",
        "fare_rules_txt_parse_outcomes",
        "fare_transfer_rules_txt_parse_outcomes",
        "feed_info_txt_parse_outcomes",
        "frequencies_txt_parse_outcomes",
        "levels_txt_parse_outcomes",
        "pathways_txt_parse_outcomes",
        "routes_txt_parse_outcomes",
        "shapes_txt_parse_outcomes",
        "stop_areas_txt_parse_outcomes",
        "stop_times_txt_parse_outcomes",
        "stops_txt_parse_outcomes",
        "transfers_txt_parse_outcomes",
        "translations_txt_parse_outcomes",
        "trips_txt_parse_outcomes",
    ] %}
        SELECT * FROM {{ source('external_gtfs_schedule' , file_outcome_table) }}
    {% if not loop.last %} UNION ALL {% endif %}
    {% endfor %}
),

dim_gtfs_schedule_file_parse_outcomes AS (
    SELECT DISTINCT
        dt,
        ts,
        success,
        exception,
        feed_file.ts AS feed_ts,
        feed_file.filename AS feed_filename,
        feed_file.original_filename AS original_filename,
        feed_file.extract_config.extracted_at AS extract_config_extracted_at,
        feed_file.extract_config.name AS extract_config_name,
        feed_file.extract_config.url AS extract_config_url,
        {{ to_url_safe_base64('feed_file.extract_config.url') }} AS extract_config_base64_url,
        feed_file.extract_config.feed_type AS extract_config_feed_type,
        feed_file.extract_config.schedule_url_for_validation AS extract_config_schedule_url_for_validation,
        TO_JSON_STRING(feed_file.extract_config.auth_query_params) AS extract_config_auth_query_params,
        TO_JSON_STRING(feed_file.extract_config.auth_headers) AS extract_config_auth_headers,
        feed_file.extract_config.computed AS extract_config_computed,
        fields,
        parsed_file.ts AS parsed_ts,
        parsed_file.filename AS parsed_filename,
        parsed_file.gtfs_filename AS parsed_gtfs_filename,
        parsed_file.csv_dialect AS parsed_csv_dialect,
        parsed_file.num_lines AS parsed_num_lines,
        parsed_file.extract_config.extracted_at AS parsed_file_config_extracted_at,
        parsed_file.extract_config.name AS parsed_file_extract_config_name,
        parsed_file.extract_config.url AS parsed_file_extract_config_url,
        {{ to_url_safe_base64('parsed_file.extract_config.url') }} AS parsed_file_extract_config_base64_url,
        parsed_file.extract_config.feed_type AS parsed_file_extract_config_feed_type,
        parsed_file.extract_config.schedule_url_for_validation AS parsed_file_extract_schedule_url_for_validation,
        TO_JSON_STRING(parsed_file.extract_config.auth_query_params) AS parsed_file_extract_auth_query_params,
        TO_JSON_STRING(parsed_file.extract_config.auth_headers) AS parsed_file_extract_auth_headers,
        parsed_file.extract_config.computed AS parsed_file_extract_computed,
    FROM unioned_outcomes
)

SELECT * FROM dim_gtfs_schedule_file_parse_outcomes

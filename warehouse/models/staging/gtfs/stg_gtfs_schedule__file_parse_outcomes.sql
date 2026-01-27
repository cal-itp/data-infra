WITH unioned_outcomes AS (
    {% for file_outcome_table in [
        "agency_txt_parse_outcomes",
        "areas_txt_parse_outcomes",
        "attributions_txt_parse_outcomes",
        "calendar_txt_parse_outcomes",
        "calendar_dates_txt_parse_outcomes",
        "fare_attributes_txt_parse_outcomes",
        "fare_leg_rules_txt_parse_outcomes",
        "fare_media_txt_parse_outcomes",
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

stg_gtfs_schedule__file_parse_outcomes AS (
    SELECT
        success AS parse_success,
        exception AS parse_exception,
        feed_file.filename AS filename,
        feed_file.extract_config.extracted_at AS _config_extract_ts,
        feed_file.extract_config.name AS feed_name,
        feed_file.extract_config.url AS feed_url,
        feed_file.original_filename AS original_filename,
        fields,
        parsed_file.gtfs_filename AS gtfs_filename,
        parsed_file.csv_dialect AS csv_dialect,
        parsed_file.num_lines AS num_lines,
        dt,
        feed_file.ts AS ts,
        {{ to_url_safe_base64('feed_file.extract_config.url') }} AS base64_url
    FROM unioned_outcomes
)

SELECT * FROM stg_gtfs_schedule__file_parse_outcomes

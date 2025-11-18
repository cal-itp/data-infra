WITH stg_gtfs_schedule__download_configs AS (
    SELECT configs.name,
           configs.url,
           {{ to_url_safe_base64('configs.url') }} AS base64_url,
           configs.feed_type,
           TO_JSON_STRING(configs.auth_headers) AS auth_headers,
           TO_JSON_STRING(configs.auth_query_params) AS auth_query_params,
           MIN(configs.dt) AS first_extracted_date,
           MAX(configs.dt) AS last_extracted_date,
           configs.schedule_url_for_validation AS schedule_url,
           {{ to_url_safe_base64('schedules.url') }} AS schedule_base64_url,
           schedules.name AS schedule_name,
           TO_JSON_STRING(schedules.auth_headers) AS schedule_auth_headers,
           TO_JSON_STRING(schedules.auth_query_params) AS schedule_auth_query_params,
           MIN(schedules.dt) AS schedule_first_extracted_date,
           MAX(schedules.dt) AS schedule_last_extracted_date
      FROM {{ source('external_gtfs_schedule', 'download_configs') }} AS configs
      LEFT JOIN {{ source('external_gtfs_schedule', 'download_configs') }} AS schedules
             ON configs.schedule_url_for_validation = schedules.url
            AND schedules.feed_type = 'schedule'
     GROUP BY
           configs.name,
           configs.url,
           configs.feed_type,
           auth_headers,
           auth_query_params,
           configs.schedule_url_for_validation,
           schedules.url,
           schedules.name,
           schedule_auth_query_params,
           schedule_auth_headers
)

SELECT * FROM stg_gtfs_schedule__download_configs

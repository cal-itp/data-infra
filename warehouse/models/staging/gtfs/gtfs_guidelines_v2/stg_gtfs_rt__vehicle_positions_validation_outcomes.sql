WITH raw_validation_outcomes AS (
    SELECT
        *,
        {{ to_url_safe_base64('`extract`.config.url') }} AS base64_url
    FROM {{ source('external_gtfs_rt', 'vehicle_positions_validation_outcomes') }}
),

stg_gtfs_rt__vehicle_positions_validation_outcomes AS (
    SELECT
        -- this mainly exists so we can use WHERE in tests
        {{ dbt_utils.surrogate_key(['`extract`.ts', 'base64_url']) }} AS key,
        dt,
        hour,
        `extract`.ts AS ts,
        `extract`.config.name AS name,
        `extract`.config.url AS url,
        `extract`.config.feed_type AS feed_type,
        `extract`.config.extracted_at AS _config_extract_ts,
        success AS validation_success,
        exception AS validation_exception,
        aggregation.filename AS aggregation_filename,
        aggregation.base64_url AS aggregation_base64_url
    FROM raw_validation_outcomes
)

SELECT * FROM stg_gtfs_rt__vehicle_positions_validation_outcomes
